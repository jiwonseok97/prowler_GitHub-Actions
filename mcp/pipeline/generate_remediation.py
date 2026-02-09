# =============================================================================
# generate_remediation.py - Terraform 리메디에이션 코드 생성 스크립트
# =============================================================================
# 목적:
#   - Prowler 결과(P0/P1/P2 우선순위) 기반으로 Terraform 리메디에이션 코드를 생성
#   - 1차: AWS Bedrock Claude Haiku로 코드 생성
#   - 2차: Bedrock 실패 시 iac/mappings/check_to_iac.yaml 매핑 스니펫 사용
#
# 입력:
#   - mcp/output/findings-scored-ai.csv
#
# 출력:
#   - remediation/fix-{check_id}.tf (개별 Terraform 파일)
#   - remediation/manifest.json (생성 파일 목록/메타데이터)
#
# 사용 흐름:
#   1) Bedrock 호출로 우선 코드 생성
#   2) 실패 시 YAML 매핑에서 스니펫 로드
#   3) 생성 코드 정리(cleanup) 후 terraform init/validate로 검증
#   4) 실패 시 최대 재시도만큼 오류 피드백을 AI에 전달해 수정 시도
#   5) 성공한 코드만 파일로 저장하고 manifest에 기록
# =============================================================================

import argparse
import json
import os
import re
import shutil  # terraform 바이너리 존재 여부 확인용
import pandas as pd

# 선택적 의존성: 없는 경우에도 스크립트가 동작하도록 안전하게 처리
try:
    import boto3
except Exception:
    boto3 = None  # boto3 미설치 시 Bedrock 호출 비활성

try:
    import yaml
except Exception:
    yaml = None  # pyyaml 미설치 시 IaC 매핑 로드 비활성

# -----------------------------------------------------------------------------
# CLI 인자
# -----------------------------------------------------------------------------
parser = argparse.ArgumentParser()
parser.add_argument("--input", required=True)
parser.add_argument("--output-dir", required=True)
parser.add_argument("--iac-mapping", default="iac/mappings/check_to_iac.yaml")
args = parser.parse_args()

# 입력 CSV 로드 (Prowler 스코어링 결과)
df = pd.read_csv(args.input)

# -----------------------------------------------------------------------------
# Bedrock 설정 (환경 변수로 오버라이드 가능)
# -----------------------------------------------------------------------------
MODEL_ID = os.getenv("BEDROCK_MODEL_ID", "anthropic.claude-3-haiku-20240307-v1:0")
BEDROCK_REGION = os.getenv("BEDROCK_REGION", "ap-northeast-2")
MAX_TOKENS = int(os.getenv("BEDROCK_MAX_TOKENS", "4096"))  # Terraform 코드 최대 길이
USE_BEDROCK = os.getenv("USE_BEDROCK", "true").lower() == "true"
# IaC 스니펫을 Bedrock보다 우선 적용할지 여부
PREFER_IAC_SNIPPET = os.getenv("PREFER_IAC_SNIPPET", "true").lower() == "true"
# provider 스키마 기반 가드레일 사용 여부
USE_SCHEMA_GUARDRAIL = os.getenv("USE_SCHEMA_GUARDRAIL", "true").lower() == "true"
# IaC 스니펫 기본 경로
IAC_SNIPPET_DIR = os.getenv("IAC_SNIPPET_DIR", "iac/terraform/snippets")
# 카테고리 스니펫 fallback 사용 여부
USE_CATEGORY_SNIPPET = os.getenv("USE_CATEGORY_SNIPPET", "true").lower() == "true"

# -----------------------------------------------------------------------------
# IaC 스니펫 매핑 로드 (Bedrock 실패 시 fallback)
# -----------------------------------------------------------------------------
iac_map = {}
if yaml and os.path.exists(args.iac_mapping):
    with open(args.iac_mapping) as f:
        iac_map = yaml.safe_load(f) or {}
    print(f"Loaded {len(iac_map)} IaC snippet mappings")

# -----------------------------------------------------------------------------
# Guardrail 설정 (문법/스키마 위반 최소화)
# -----------------------------------------------------------------------------
COMPUTED_ATTRS = {
    "arn",
    "id",
    "key_id",
    "owner_id",
    "creation_date",
    "create_date",
    "created_date",
    "unique_id",
}

# Terraform으로 해결 불가능한 체크 (AWS Console/수동 설정만 가능)
SKIP_CHECKS = {
    "account_maintain_current_contact_details",
    "account_maintain_different_contact_details_to_security_billing_and_operations",
    "account_security_contact_information_is_registered",
    "account_security_questions_are_registered_in_the_aws_account",
}

DATA_ONLY_RESOURCE_TYPES = {
    "aws_kms_ciphertext",
    "aws_iam_policy_document",
    "aws_caller_identity",
    "aws_partition",
    "aws_region",
    "aws_availability_zones",
    "aws_arn",
}

EXPLANATION_PATTERNS = [
    re.compile(r"^\s*This\s+Terraform\s+code", re.IGNORECASE),
    re.compile(r"^\s*The\s+Terraform\s+code", re.IGNORECASE),
    re.compile(r"^\s*The\s+provided\s+Terraform\s+code", re.IGNORECASE),
    re.compile(r"^\s*This\s+should", re.IGNORECASE),
    re.compile(r"^\s*Here\s+is", re.IGNORECASE),
    re.compile(r"^\s*Below\s+is", re.IGNORECASE),
    re.compile(r"^\s*\d+\.\s+"),
    re.compile(r"^\s*[-*]\s+"),
]

HCL_START_RE = re.compile(
    r"^\s*(#|//|resource\b|data\b|provider\b|variable\b|locals\b|terraform\b|"
    r"output\b|module\b|import\b|\})"
)

# provider 스키마에서 추출한 computed-only 속성 맵
SCHEMA_COMPUTED_ATTRS = {}


def _terraform_cli_available():
    # Terraform CLI가 PATH에 있는지 확인
    return shutil.which("terraform") is not None  # PATH에 terraform이 있으면 True


def _load_schema_computed_attrs():
    # 스키마 가드레일이 비활성화면 빈 맵 반환
    if not USE_SCHEMA_GUARDRAIL:  # 가드레일 비활성 체크
        return {}  # 비활성화 시 빈 맵 반환
    # 이미 로드된 캐시가 있으면 그대로 반환
    if SCHEMA_COMPUTED_ATTRS:  # 캐시가 있으면 재사용
        return SCHEMA_COMPUTED_ATTRS  # 캐시된 값 반환
    # Terraform CLI가 없으면 스키마 로딩 불가
    if not _terraform_cli_available():  # terraform 바이너리 존재 여부 확인
        return {}  # 실행 불가 시 빈 맵 반환
    # 표준 라이브러리 로컬 import (필요 시에만)
    import tempfile  # 임시 디렉터리 생성용
    import subprocess  # terraform 명령 실행용
    # 임시 작업 디렉터리 생성
    work = tempfile.mkdtemp(prefix="tf-schema-")  # 스키마 조회용 임시 폴더
    try:
        # 스키마 로딩용 최소 main.tf 작성
        with open(os.path.join(work, "main.tf"), "w") as f:  # main.tf 생성
            # required_providers 블록 정의
            f.write('terraform {\n')  # terraform 블록 시작
            # aws 프로바이더 소스 지정
            f.write('  required_providers {\n')  # required_providers 블록 시작
            # aws provider 핀 고정 (소스만 지정)
            f.write('    aws = {\n')  # aws 프로바이더 블록 시작
            # registry 소스 지정
            f.write('      source = "hashicorp/aws"\n')  # aws 소스 지정
            # 블록 종료
            f.write('    }\n')  # aws 프로바이더 블록 종료
            # required_providers 종료
            f.write('  }\n')  # required_providers 종료
            # terraform 블록 종료
            f.write('}\n')  # terraform 블록 종료
            # provider 블록 추가
            f.write('provider "aws" {\n')  # provider 블록 시작
            # 리전 고정
            f.write('  region = "ap-northeast-2"\n')  # 리전 설정
            # provider 블록 종료
            f.write('}\n')  # provider 블록 종료
        # terraform init 실행 (backend 불필요)
        r1 = subprocess.run(  # init 실행
            ["terraform", "init", "-backend=false", "-input=false", "-no-color"],  # init 옵션
            cwd=work, capture_output=True, text=True, timeout=120  # 실행 경로/옵션
        )
        # init 실패 시 빈 결과 반환
        if r1.returncode != 0:  # init 실패 체크
            return {}  # 실패 시 빈 맵 반환
        # provider schema JSON 출력
        r2 = subprocess.run(  # schema 출력 실행
            ["terraform", "providers", "schema", "-json"],  # schema 출력 옵션
            cwd=work, capture_output=True, text=True, timeout=120  # 실행 경로/옵션
        )
        # schema 조회 실패 시 빈 결과 반환
        if r2.returncode != 0:  # schema 실행 실패 체크
            return {}  # 실패 시 빈 맵 반환
        # JSON 파싱
        schema = json.loads(r2.stdout)  # schema JSON 파싱
        # aws provider 스키마 위치 찾기
        provider = schema.get("provider_schemas", {}).get(  # provider 위치 탐색
            "registry.terraform.io/hashicorp/aws"  # aws provider 키
        )
        # provider 스키마 없으면 종료
        if not provider:  # provider 스키마 존재 체크
            return {}  # 없으면 빈 맵 반환
        # 리소스 스키마 추출
        resource_schemas = provider.get("resource_schemas", {})  # 리소스 스키마 목록
        # 각 리소스별 computed-only 속성 추출
        for rtype, rschema in resource_schemas.items():  # 리소스 스키마 순회
            # 최상위 attribute 목록
            attrs = rschema.get("block", {}).get("attributes", {})  # 속성 맵 추출
            # computed-only 속성 필터링
            computed = {  # computed-only 속성 집합
                name  # 속성 이름
                for name, meta in attrs.items()  # 속성 메타 순회
                if meta.get("computed") and not meta.get("optional") and not meta.get("required")  # computed-only 조건
            }
            # computed-only 속성이 있으면 맵에 저장
            if computed:  # computed-only 존재 여부
                SCHEMA_COMPUTED_ATTRS[rtype] = computed  # 리소스 타입별 저장
        # 캐시된 맵 반환
        return SCHEMA_COMPUTED_ATTRS  # computed-only 맵 반환
    finally:
        # 임시 디렉터리 삭제
        shutil.rmtree(work, ignore_errors=True)  # 임시 폴더 정리


def _brace_delta(line: str) -> int:
    return line.count("{") - line.count("}")


def _strip_code_fences(code: str) -> str:
    lines = []
    for line in code.splitlines():
        if line.strip().startswith("```"):
            continue
        lines.append(line)
    return "\n".join(lines)


def _comment_explanations(lines):
    out = []
    in_expl = False
    in_heredoc = False
    heredoc_marker = None
    for line in lines:
        # heredoc 내부에서는 설명 패턴 매칭 건너뜀
        if in_heredoc:
            out.append(line)
            if line.strip() == heredoc_marker:
                in_heredoc = False
                heredoc_marker = None
            continue
        # heredoc 시작 감지
        m = re.search(r"<<-?\s*([A-Z_]+)\s*$", line)
        if m:
            in_heredoc = True
            heredoc_marker = m.group(1)
            out.append(line)
            continue
        if any(pat.match(line) for pat in EXPLANATION_PATTERNS):
            in_expl = True
            out.append("# " + line.strip())
            continue
        if in_expl:
            if HCL_START_RE.match(line):
                in_expl = False
                out.append(line)
            else:
                out.append("# " + line.strip())
            continue
        out.append(line)
    return out


def _remove_import_blocks(lines):
    out = []
    in_import = False
    brace = 0
    for line in lines:
        if not in_import and re.match(r"^\s*import\s*\{", line):
            in_import = True
            brace += _brace_delta(line)
            if brace <= 0:
                in_import = False
            continue
        if in_import:
            brace += _brace_delta(line)
            if brace <= 0:
                in_import = False
            continue
        out.append(line)
    return out


def _remove_terraform_blocks(lines):
    # 결과를 담을 리스트
    out = []
    # terraform 블록 내부 여부
    in_tf = False
    # 중괄호 카운터
    brace = 0
    # 모든 라인 순회
    for line in lines:
        # terraform 블록 시작 감지
        if not in_tf and re.match(r"^\s*terraform\s*\{", line):
            # 블록 진입
            in_tf = True
            # 중괄호 카운트 갱신
            brace += _brace_delta(line)
            # 한 줄 블록이면 즉시 종료
            if brace <= 0:
                # 블록 종료
                in_tf = False
            # terraform 블록 라인은 제거
            continue
        # terraform 블록 내부 처리
        if in_tf:
            # 중괄호 카운트 갱신
            brace += _brace_delta(line)
            # 블록 종료 조건
            if brace <= 0:
                # 블록 종료
                in_tf = False
            # 블록 내부 라인은 제거
            continue
        # 일반 라인은 유지
        out.append(line)
    # 결과 반환
    return out


def _remove_provider_blocks(lines):
    out = []
    in_prov = False
    brace = 0
    for line in lines:
        if not in_prov and re.match(r'^\s*provider\s+"aws"\s*\{', line):
            in_prov = True
            brace += _brace_delta(line)
            if brace <= 0:
                in_prov = False
            continue
        if in_prov:
            brace += _brace_delta(line)
            if brace <= 0:
                in_prov = False
            continue
        if re.match(r"^\s*provider\s*=\s*aws\.\S+", line):
            continue
        out.append(line)
    return out


def _fix_invalid_type_tokens(line: str) -> str:
    line = re.sub(r'^(\s*(resource|data)\s+")aws:([^"]+")', r"\1aws_\3", line)
    return line


def _convert_data_only_resources(lines):
    out = []
    for line in lines:
        line = _fix_invalid_type_tokens(line)
        m = re.match(r'^(\s*)resource\s+"([^"]+)"\s+"([^"]+)"\s*\{', line)
        if m and m.group(2) in DATA_ONLY_RESOURCE_TYPES:
            indent, rtype, rname = m.group(1), m.group(2), m.group(3)
            out.append(f'{indent}data "{rtype}" "{rname}" {{')
            continue
        out.append(line)
    return out


def _strip_unconfigurable_attrs_in_resources(lines, extra_attrs=None):
    attrs = set(COMPUTED_ATTRS)
    if extra_attrs:
        attrs.update(extra_attrs)
    if not attrs:
        return lines
    attr_re = re.compile(r"^\s*(" + "|".join(sorted(attrs)) + r")\s*=")

    out = []
    in_resource = False
    in_heredoc = False
    heredoc_marker = None
    brace = 0
    for line in lines:
        # heredoc 내부에서는 attr 매칭/brace 카운팅 건너뜀
        if in_heredoc:
            out.append(line)
            if line.strip() == heredoc_marker:
                in_heredoc = False
                heredoc_marker = None
            continue
        if not in_resource and re.match(r'^\s*resource\s+"[^"]+"\s+"[^"]+"\s*\{', line):
            in_resource = True
            brace = _brace_delta(line)
            out.append(line)
            continue
        if in_resource:
            # heredoc 시작 감지
            m = re.search(r"<<-?\s*([A-Z_]+)\s*$", line)
            if m:
                in_heredoc = True
                heredoc_marker = m.group(1)
                out.append(line)
                continue
            if attr_re.match(line):
                continue
            brace += _brace_delta(line)
            out.append(line)
            if brace <= 0:
                in_resource = False
            continue
        out.append(line)
    return out


def _strip_schema_computed_attrs(lines):
    # 스키마 기반 computed-only 속성 제거
    schema_map = _load_schema_computed_attrs()  # computed-only 맵 로드
    # 스키마가 없으면 그대로 반환
    if not schema_map:  # 스키마 맵이 비어있으면
        return lines  # 원본 라인 반환
    # 결과 라인 리스트
    out = []  # 출력 라인 버퍼
    # resource 블록 내부 여부
    in_resource = False  # resource 블록 상태
    # 현재 resource 타입
    current_type = None  # 현재 리소스 타입
    # 현재 resource의 computed-only 속성
    current_attrs = set()  # 현재 리소스 속성 집합
    # 현재 resource의 속성 매칭 정규식
    current_re = None  # 속성 제거용 정규식
    # heredoc 내부 여부
    in_heredoc = False  # heredoc 상태
    # heredoc 종료 마커
    heredoc_marker = None  # heredoc 종료 라벨
    # 중괄호 카운트
    brace = 0  # 블록 깊이 카운터
    # 라인 순회
    for line in lines:  # 입력 라인 반복
        # heredoc 내부는 그대로 유지
        if in_heredoc:  # heredoc 내부면
            out.append(line)  # 라인 그대로 유지
            if line.strip() == heredoc_marker:  # 종료 마커 체크
                in_heredoc = False  # heredoc 종료
                heredoc_marker = None  # 마커 초기화
            continue  # 다음 라인으로
        # heredoc 시작 감지
        m = re.search(r"<<-?\s*([A-Z_]+)\s*$", line)  # heredoc 시작 패턴
        if m:  # heredoc 시작이면
            in_heredoc = True  # heredoc 진입
            heredoc_marker = m.group(1)  # 종료 마커 저장
            out.append(line)  # 라인 유지
            continue  # 다음 라인으로
        # resource 블록 시작 감지
        if not in_resource:  # resource 내부가 아니면
            m = re.match(r'^\s*resource\s+"([^"]+)"\s+"([^"]+)"\s*\{', line)  # resource 시작
            if m:  # resource 시작이면
                in_resource = True  # resource 진입
                current_type = m.group(1)  # 리소스 타입 저장
                current_attrs = schema_map.get(current_type, set())  # 타입별 속성 집합
                if current_attrs:  # 속성이 있으면
                    current_re = re.compile(  # 속성 제거 정규식 생성
                        r"^\s*(" + "|".join(sorted(current_attrs)) + r")\s*="
                    )
                else:  # 속성이 없으면
                    current_re = None  # 정규식 비활성
                brace = _brace_delta(line)  # brace 초기화
                out.append(line)  # 블록 시작 라인 유지
                continue  # 다음 라인으로
        # resource 블록 내부 처리
        if in_resource:  # resource 내부면
            if current_re and current_re.match(line):  # computed-only 속성이면
                brace += _brace_delta(line)  # brace 갱신
                if brace <= 0:  # 블록 종료면
                    in_resource = False  # resource 종료
                    current_type = None  # 타입 초기화
                    current_attrs = set()  # 속성 초기화
                    current_re = None  # 정규식 초기화
                continue  # 해당 라인 제거
            brace += _brace_delta(line)  # brace 갱신
            out.append(line)  # 라인 유지
            if brace <= 0:  # 블록 종료면
                in_resource = False  # resource 종료
                current_type = None  # 타입 초기화
                current_attrs = set()  # 속성 초기화
                current_re = None  # 정규식 초기화
            continue  # 다음 라인으로
        # 일반 라인은 유지
        out.append(line)  # 일반 라인 유지
    # 처리 결과 반환
    return out  # 결과 라인 반환



def _repair_unclosed_heredoc(lines):
    # 미닫힌 heredoc을 안전하게 대체하여 HCL 파싱 오류 방지
    out = []  # 출력 라인 버퍼
    in_heredoc = False  # heredoc 내부 여부
    heredoc_marker = None  # heredoc 종료 마커
    start_idx = None  # heredoc 시작 라인 인덱스
    start_line = None  # heredoc 시작 라인 내용
    for line in lines:  # 라인 순회
        if not in_heredoc:  # heredoc 밖이면
            m = re.match(r'^\s*([A-Za-z0-9_]+)\s*=\s*<<-?\s*([A-Z_]+)\s*$', line)  # heredoc 시작 감지
            if m:  # heredoc 시작이면
                in_heredoc = True  # heredoc 진입
                heredoc_marker = m.group(2)  # 종료 마커 저장
                start_idx = len(out)  # 시작 위치 기록
                start_line = line  # 시작 라인 기록
                out.append(line)  # 원본 라인 보존
                continue  # 다음 라인으로
            out.append(line)  # 일반 라인 추가
            continue  # 다음 라인으로
        # heredoc 내부 처리
        out.append(line)  # heredoc 내용 유지
        if line.strip() == heredoc_marker:  # 종료 마커면
            in_heredoc = False  # heredoc 종료
            heredoc_marker = None  # 마커 초기화
            start_idx = None  # 시작 인덱스 초기화
            start_line = None  # 시작 라인 초기화
    # 파일 끝까지 heredoc이 닫히지 않았으면 대체
    if in_heredoc and start_idx is not None and start_line:  # 미닫힘 상태 확인
        indent = re.match(r'^(\s*)', start_line).group(1)  # 들여쓰기 추출
        attr = re.match(r'^\s*([A-Za-z0-9_]+)\s*=', start_line).group(1)  # 속성명 추출
        out = out[:start_idx]  # heredoc 시작 이전으로 잘라냄
        out.append(f'{indent}{attr} = "{{}}"')  # 안전한 빈 JSON으로 대체
    return out  # 결과 반환


def _balance_braces(lines):
    # 중괄호 개수가 맞지 않으면 보정하여 "Unclosed config" 완화
    out = []  # 출력 라인 버퍼
    brace = 0  # 중괄호 카운터
    in_heredoc = False  # heredoc 내부 여부
    heredoc_marker = None  # heredoc 종료 마커
    for line in lines:  # 라인 순회
        if in_heredoc:  # heredoc 내부면
            out.append(line)  # 그대로 추가
            if line.strip() == heredoc_marker:  # 종료 마커면
                in_heredoc = False  # heredoc 종료
                heredoc_marker = None  # 마커 초기화
            continue  # 다음 라인으로
        m = re.search(r"<<-?\s*([A-Z_]+)\s*$", line)  # heredoc 시작 감지
        if m:  # heredoc 시작이면
            in_heredoc = True  # heredoc 진입
            heredoc_marker = m.group(1)  # 종료 마커 저장
            out.append(line)  # 라인 추가
            continue  # 다음 라인으로
        brace += _brace_delta(line)  # 중괄호 카운트 갱신
        out.append(line)  # 라인 추가
    # 남은 중괄호만큼 닫기
    if brace > 0:  # 닫히지 않은 블록이 있으면
        out.extend(["}"] * brace)  # 부족한 닫는 괄호 추가
    return out  # 결과 반환


def _sanitize_label(name: str, prefix: str | None = None) -> str:
    # 라벨에 허용되지 않는 문자를 '_'로 치환
    label = re.sub(r"[^A-Za-z0-9_]", "_", name or "")
    # 연속된 '_'를 하나로 축소
    label = re.sub(r"_+", "_", label).strip("_")
    # 빈 라벨이면 기본값 사용
    if not label:
        label = "resource"
    # 숫자로 시작하면 접두어 추가
    if re.match(r"^\d", label):
        label = f"r_{label}"
    # prefix가 있고 이미 없으면 prefix 추가
    if prefix and not label.startswith(prefix):
        label = f"{prefix}{label}"
    # 정규화된 라벨 반환
    return label


def _replace_refs(lines, mapping):
    # 결과 라인 저장
    out = []
    # heredoc 내부 여부
    in_heredoc = False
    # heredoc 종료 마커
    heredoc_marker = None
    # 라인 순회
    for line in lines:
        # heredoc 내부는 치환하지 않음
        if in_heredoc:
            out.append(line)
            if line.strip() == heredoc_marker:
                in_heredoc = False
                heredoc_marker = None
            continue
        # heredoc 시작 감지
        m = re.search(r"<<-?\s*([A-Z_]+)\s*$", line)
        if m:
            in_heredoc = True
            heredoc_marker = m.group(1)
            out.append(line)
            continue
        # 매핑된 참조 치환
        for kind, rtype, old, new in mapping:
            if old == new:
                continue
            if kind == "data":
                line = re.sub(
                    rf"\bdata\.{re.escape(rtype)}\.{re.escape(old)}\b",
                    f"data.{rtype}.{new}",
                    line,
                )
            line = re.sub(
                rf"\b{re.escape(rtype)}\.{re.escape(old)}\b",
                f"{rtype}.{new}",
                line,
            )
        out.append(line)
    # 치환 결과 반환
    return out


def _normalize_block_names(lines):
    # 변경 매핑 저장
    mapping = []
    # 이름 중복 카운트
    counts = {}
    # 결과 라인 저장
    out = []
    # 라인 순회
    for line in lines:
        # resource/data 블록 선언 감지
        m = re.match(r'^(\s*)(resource|data)\s+"([^"]+)"\s+"([^"]+)"\s*\{', line)
        if m:
            # 캡처된 정보 추출
            indent, kind, rtype, name = m.groups()
            # resource는 remediation_ 접두어 강제
            prefix = "remediation_" if kind == "resource" else None
            # 라벨 정규화
            base_name = _sanitize_label(name, prefix=prefix)
            # 중복 판단 키
            key = (kind, rtype, base_name)
            # 현재 중복 인덱스
            idx = counts.get(key, 0)
            # 중복이면 suffix 부여
            new_name = base_name if idx == 0 else f"{base_name}_{idx}"
            # 카운트 갱신
            counts[key] = idx + 1
            # 참조 치환을 위한 매핑 저장
            mapping.append((kind, rtype, name, new_name))
            # 라벨이 바뀐 블록 선언 라인 생성
            line = f'{indent}{kind} "{rtype}" "{new_name}" {{'
        out.append(line)
    # 매핑이 없으면 그대로 반환
    if not mapping:
        return out
    # 참조 치환 적용
    return _replace_refs(out, mapping)


def sanitize_tf_code(code, extra_unconfig_attrs=None):
    if not code:
        return ""
    code = _strip_code_fences(code)
    lines = code.splitlines()
    lines = _comment_explanations(lines)
    lines = _remove_import_blocks(lines)
    # terraform { } 블록 제거
    lines = _remove_terraform_blocks(lines)
    lines = _convert_data_only_resources(lines)
    lines = _remove_provider_blocks(lines)
    # provider 스키마 기반 computed-only 속성 제거
    lines = _strip_schema_computed_attrs(lines)
    lines = _strip_unconfigurable_attrs_in_resources(lines, extra_unconfig_attrs)
    # resource/data 이름 정규화 및 참조 동기화
    lines = _normalize_block_names(lines)
    # 미닫힌 heredoc 보정
    lines = _repair_unclosed_heredoc(lines)
    # 중괄호 균형 보정
    lines = _balance_braces(lines)

    # 앞/뒤 공백 라인 제거
    while lines and lines[0].strip() == "":
        lines.pop(0)
    while lines and lines[-1].strip() == "":
        lines.pop()
    return "\n".join(lines).strip()


def apply_error_fixes(tf_code, error_msg):
    extra_attrs = set()
    for pat in [
        r'Can\'t configure a value for "([^"]+)"',
        r'Value for unconfigurable attribute.*?"([^"]+)"',
    ]:
        for m in re.findall(pat, error_msg, flags=re.DOTALL):
            extra_attrs.add(m)
    if extra_attrs:
        return sanitize_tf_code(tf_code, extra_unconfig_attrs=extra_attrs)
    if any(
        key in error_msg
        for key in ["Unsupported block type", "Invalid block definition", "Invalid character"]
    ):
        return sanitize_tf_code(tf_code)
    return tf_code


def validate_with_autofix(tf_code, max_auto_fixes=2):
    last_err = ""
    for _ in range(max_auto_fixes + 1):
        ok, err = validate_terraform(tf_code)
        if ok:
            return True, tf_code, ""
        last_err = err
        fixed = apply_error_fixes(tf_code, err)
        if fixed == tf_code:
            break
        tf_code = fixed
    return False, tf_code, last_err


def categorize_check_id(check_id: str) -> str:
    """체크 ID 접두어 기준으로 대략적인 카테고리 분류 (리포팅용)."""
    cid = (check_id or "").lower()
    if cid.startswith("iam_"):
        return "iam"
    if cid.startswith("s3_"):
        return "s3"
    if cid.startswith("cloudtrail_"):
        return "cloudtrail"
    if cid.startswith("cloudwatch_"):
        return "cloudwatch"
    if cid.startswith("kms_"):
        return "kms"
    if cid.startswith("ec2_") or cid.startswith("vpc_") or cid.startswith("network"):
        return "network-ec2-vpc"
    if cid.startswith("organizations_") or cid.startswith("account_"):
        return "org-account"
    return "other"


def call_bedrock(prompt):
    """AWS Bedrock Claude 3 Haiku API를 호출해 Terraform 코드를 생성."""
    if not USE_BEDROCK or boto3 is None:
        print("Bedrock disabled or boto3 unavailable")
        return None
    try:
        client = boto3.client("bedrock-runtime", region_name=BEDROCK_REGION)
        body = {
            "anthropic_version": "bedrock-2023-05-31",
            "max_tokens": MAX_TOKENS,
            "temperature": 0.1,  # 낮은 temperature로 일관된 코드 생성 유도
            "messages": [{"role": "user", "content": prompt}],
        }
        resp = client.invoke_model(
            modelId=MODEL_ID,
            contentType="application/json",
            accept="application/json",
            body=json.dumps(body),
        )
        payload = json.loads(resp["body"].read())
        parts = payload.get("content", [])
        if not parts:
            return None
        return parts[0].get("text", "").strip()
    except Exception as e:
        print(f"Bedrock error: {e}")
        return None


# Bedrock 오류 수정 재시도 횟수 (환경 변수로 조정 가능)
MAX_RETRIES = int(os.getenv("BEDROCK_MAX_RETRIES", "2"))


def validate_terraform(tf_code):
    """임시 디렉터리에 코드를 작성하고 terraform init/validate로 검증.

    - provider 블록은 제거하고, 고정된 provider/backend를 별도 파일로 주입
    - init/validate 실패 시 에러 메시지 반환
    """
    import tempfile, subprocess, shutil
    work = tempfile.mkdtemp(prefix="tf-validate-")
    try:
        # main.tf 작성 (provider 블록 제거 + provider 별칭 사용 제거)
        import re as _re
        lines = tf_code.split('\n')
        filtered = []
        in_prov = False
        brace = 0
        for line in lines:
            if not in_prov and _re.match(r'^\s*provider\s+"aws"\s*\{', line):
                in_prov = True
                brace += line.count('{') - line.count('}')
                if brace <= 0:
                    in_prov = False
                continue
            if in_prov:
                brace += line.count('{') - line.count('}')
                if brace <= 0:
                    in_prov = False
                continue
            # provider = aws.xxx 형태의 alias 지정 제거
            if _re.match(r'^\s*provider\s*=\s*aws\.\S+', line):
                continue
            filtered.append(line)
        with open(os.path.join(work, "main.tf"), "w") as f:
            f.write('\n'.join(filtered) + '\n')
        with open(os.path.join(work, "provider.tf"), "w") as f:
            f.write(
                'provider "aws" {\n'
                '  region = "ap-northeast-2"\n'
                '}\n'
            )
        with open(os.path.join(work, "backend.tf"), "w") as f:
            f.write(
                'terraform {\n'
                '  backend "local" {\n'
                '    path = "terraform.tfstate"\n'
                '  }\n'
                '}\n'
            )

        # init
        r1 = subprocess.run(
            ["terraform", "init", "-input=false", "-no-color"],
            cwd=work, capture_output=True, text=True, timeout=120
        )
        if r1.returncode != 0:
            return False, f"init failed: {r1.stdout}\n{r1.stderr}"

        # validate
        r2 = subprocess.run(
            ["terraform", "validate", "-no-color"],
            cwd=work, capture_output=True, text=True, timeout=60
        )
        if r2.returncode != 0:
            return False, r2.stdout + r2.stderr
        return True, ""
    except Exception as e:
        return False, str(e)
    finally:
        shutil.rmtree(work, ignore_errors=True)


def make_fix_prompt(original_prompt, tf_code, error_msg):
    """검증 실패 에러를 포함해 재생성용 프롬프트를 구성."""
    return f"""{original_prompt}

The previous attempt generated this code:
{tf_code}

But terraform validate returned this error:
{error_msg}

Fix the code to resolve this error. Output ONLY the corrected Terraform HCL code, nothing else."""


def _read_snippet_file(path):
    # 스니펫 파일 읽기 헬퍼
    if not path:  # 경로가 없으면
        return None  # None 반환
    if not path.endswith(".tf"):  # .tf만 허용
        return None  # .tf가 아니면 무시
    if os.path.exists(path):  # 파일이 존재하면
        with open(path) as f:  # 파일 열기
            return f.read().strip()  # 내용 반환
    return None  # 파일 없으면 None


def fallback_from_iac_snippet(check_id, category=None):
    """Bedrock 실패 시 check_to_iac.yaml 매핑에서 스니펫을 로드."""
    snippet_path = iac_map.get(check_id)  # 체크 ID 매핑 경로 조회
    snippet = _read_snippet_file(snippet_path)  # 매핑된 스니펫 읽기
    if snippet:  # 매핑된 스니펫이 있으면
        return snippet  # 매핑 스니펫 반환
    if not USE_CATEGORY_SNIPPET:  # 카테고리 스니펫 비활성화면
        return None  # 바로 종료
    if category:  # 카테고리가 있으면
        category_path = os.path.join(IAC_SNIPPET_DIR, f"{category}.tf")  # 카테고리 스니펫 경로
        snippet = _read_snippet_file(category_path)  # 카테고리 스니펫 읽기
        if snippet:  # 카테고리 스니펫이 있으면
            return snippet  # 카테고리 스니펫 반환
    default_path = os.path.join(IAC_SNIPPET_DIR, "default.tf")  # 기본 스니펫 경로
    return _read_snippet_file(default_path)  # 기본 스니펫 반환


def make_remediation_prompt(row):
    """finding 정보를 기반으로 Terraform 생성 프롬프트를 구성."""
    return f"""Generate Terraform code to fix this AWS security finding.

Check ID: {row.get('check_id', '')}
Title: {row.get('check_title', '')}
Severity: {row.get('severity', '')}
Resource UID: {row.get('resource_uid', '')}
Region: {row.get('region', 'ap-northeast-2')}
Recommendation: {row.get('recommendation_text', '')}

Requirements:
- Output ONLY valid Terraform HCL code, nothing else
- No markdown, no explanations, no code fences, no text before or after the code
- Always create NEW resources to remediate the finding. Do NOT try to modify or import existing resources
- NEVER use "import" blocks
- NEVER set computed/read-only attributes (arn, id, key_id, owner_id, creation_date, unique_id) in resource blocks
- NEVER reference existing resources by hardcoded ARN or ID in resource blocks
- Use "data" sources ONLY when you need to look up existing resource info (e.g., data "aws_caller_identity")
- Include a single provider "aws" block for ap-northeast-2 region WITHOUT alias
- NEVER use provider aliases (no "alias" in provider, no "provider = aws.xxx" in resources)
- For IAM policies, use jsonencode() instead of heredoc (<<EOF) to avoid string termination issues
- Add HCL comments (lines starting with #) explaining what the code does
- Make sure all required attributes are set for each resource type
- Use unique resource names with a "remediation_" prefix to avoid conflicts

Output the Terraform code:"""


# 출력 디렉터리 보장
os.makedirs(args.output_dir, exist_ok=True)

# P0/P1/P2 우선순위만 자동 리메디에이션 대상 (P3는 수동)
high_priority = df[df['priority'].isin(['P0', 'P1', 'P2'])]
print(f"Found {len(high_priority)} high-priority findings (P0/P1/P2) out of {len(df)} total")

# check_id 기준 중복 제거 (같은 체크가 여러 리소스에 반복될 수 있음)
unique_checks = high_priority.drop_duplicates(subset=['check_id'], keep='first')
skipped_checks = [c for c in unique_checks['check_id'] if c in SKIP_CHECKS]
unique_checks = unique_checks[~unique_checks['check_id'].isin(SKIP_CHECKS)]
print(f"Unique check_ids: {len(unique_checks)} (skipped {len(skipped_checks)} non-terraform checks: {skipped_checks})")

# 생성 결과/통계
generated = []
bedrock_failures = 0

for _, row in unique_checks.iterrows():
    # check_id를 파일명에 안전하게 사용하도록 문자 치환
    check_id = str(row.get('check_id', 'unknown')).replace('/', '-').replace(':', '-')
    category = categorize_check_id(row.get('check_id', ''))

    # 생성용 프롬프트 구성
    original_prompt = make_remediation_prompt(row)

    # 템플릿(IaC 스니펫) 우선 적용 옵션
    # 초기 코드 결과는 없음
    tf_code = None
    # 기본 소스는 bedrock으로 표시
    source = "bedrock"
    # 템플릿 우선 옵션이 켜져 있으면 스니펫부터 시도
    if PREFER_IAC_SNIPPET:
        # 체크 ID에 매핑된 스니펫 로드
        tf_code = fallback_from_iac_snippet(str(row.get('check_id', '')), category)  # 체크 ID/카테고리 스니펫 조회
        # 스니펫이 있으면 소스를 갱신하고 로그 출력
        if tf_code:
            source = "iac_snippet"
            print(f"IaC snippet used for: {check_id}")

    # IaC 스니펫이 없거나 비활성인 경우 Bedrock 사용
    if not tf_code:
        # Bedrock으로 코드 생성 시도
        tf_code = call_bedrock(original_prompt)
        # 소스는 bedrock으로 유지
        source = "bedrock"

    # Bedrock 실패 시 IaC 스니펫으로 대체
    if not tf_code:
        # Bedrock 실패 카운트 증가
        bedrock_failures += 1
        # 스니펫으로 대체 시도
        tf_code = fallback_from_iac_snippet(str(row.get('check_id', '')), category)  # 체크 ID/카테고리 스니펫 조회
        # 스니펫이 있으면 소스 갱신 및 로그 출력
        if tf_code:
            source = "iac_snippet"
            print(f"Fallback IaC snippet used for: {check_id}")

    if tf_code:
        tf_code = sanitize_tf_code(tf_code)

        if not tf_code:
            print(f"SKIP (generated code was empty after cleanup): {check_id}")
            continue

        # 생성 코드 검증 + 자동 수정(가드레일) 적용
        ok, tf_code, err = validate_with_autofix(tf_code)

        # Bedrock 코드가 실패하면 IaC 스니펫으로 재시도
        if not ok and source == "bedrock":
            fallback = fallback_from_iac_snippet(str(row.get('check_id', '')), category)  # 체크 ID/카테고리 스니펫 조회
            if fallback:
                fb_code = sanitize_tf_code(fallback)
                ok, fb_code, err = validate_with_autofix(fb_code)
                if ok:
                    tf_code = fb_code
                    source = "iac_snippet"

        # 여전히 실패하면 Bedrock 수정 요청 재시도
        if not ok:
            for attempt in range(1, MAX_RETRIES + 1):
                print(f"  validate FAILED (attempt {attempt}/{MAX_RETRIES}): {err[:500]}")
                fix_response = call_bedrock(make_fix_prompt(original_prompt, tf_code, err))
                if not fix_response:
                    continue
                tf_code = sanitize_tf_code(fix_response)
                ok, tf_code, err = validate_with_autofix(tf_code)
                if ok:
                    print(f"  validate OK (attempt {attempt})")
                    break

        if not ok:
            print(f"SKIP {check_id}: failed validation after {MAX_RETRIES} attempts")
            continue

        # 개별 .tf 파일로 저장
        filename = f"fix-{check_id}.tf"
        filepath = os.path.join(args.output_dir, filename)
        with open(filepath, 'w') as f:
            f.write(tf_code)
        generated.append({
            'check_id': row.get('check_id'),
            'check_title': row.get('check_title'),
            'file': filename,
            'priority': row.get('priority'),
            'category': category,
            'source': source
        })
        print(f"Generated: {filename}")
    else:
        print(f"SKIP (no Bedrock response and no IaC snippet): {check_id}")

# 생성 파일 목록을 manifest.json으로 저장
with open(os.path.join(args.output_dir, 'manifest.json'), 'w') as f:
    json.dump(generated, f, indent=2)

print(f"Total generated: {len(generated)} remediation files")
if bedrock_failures > 0:
    print(f"WARNING: Bedrock failed for {bedrock_failures}/{len(high_priority)} findings")
