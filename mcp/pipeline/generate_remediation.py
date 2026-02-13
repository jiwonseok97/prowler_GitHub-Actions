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
DEFAULT_BEDROCK_REGION = "ap-northeast-2"
DEFAULT_MODEL_ID = "anthropic.claude-3-haiku-20240307-v1:0"
MODEL_ID = os.getenv("BEDROCK_MODEL_ID", DEFAULT_MODEL_ID)
BEDROCK_REGION = os.getenv("BEDROCK_REGION", DEFAULT_BEDROCK_REGION)
# Force Seoul region to avoid accidental Osaka calls
if BEDROCK_REGION != DEFAULT_BEDROCK_REGION:
    print(f"[Bedrock] Override region {BEDROCK_REGION} -> {DEFAULT_BEDROCK_REGION}")
    BEDROCK_REGION = DEFAULT_BEDROCK_REGION
# Normalize to ARN if model id is a short name
if not MODEL_ID.startswith("arn:aws:bedrock:"):
    MODEL_ID = f"arn:aws:bedrock:{BEDROCK_REGION}::foundation-model/{MODEL_ID}"
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
# IAM 리소스 생성 허용 여부 (기본: false → data source 참조로 전환)
ALLOW_IAM_CREATE = os.getenv("ALLOW_IAM_CREATE", "false").lower() == "true"
# 검증 실패 시 스킵 허용 여부 (기본: false → 스텁 생성)
ALLOW_SKIP = os.getenv("ALLOW_SKIP", "false").lower() == "true"

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
    "iam_policy_cloudshell_admin_not_attached",       # 수동 detach 필요
    "iam_user_console_access_unused",                 # 수동 비활성화 필요
    "iam_inline_policy_no_full_access_to_kms",        # 수동 정책 수정 필요
    "organizations_account_part_of_organizations",    # 조직 가입 필요 (자동 적용 어려움)
}

# 동일 singleton AWS 리소스를 생성하는 체크들 → 하나의 파일로 통합
CONSOLIDATE_CHECKS = {
    "iam_password_policy_expires_passwords_within_90_days_or_less": "fix-iam_password_policy.tf",
    "iam_password_policy_minimum_length_14": "fix-iam_password_policy.tf",
    "iam_password_policy_lowercase": "fix-iam_password_policy.tf",
    "iam_password_policy_number": "fix-iam_password_policy.tf",
    "iam_password_policy_reuse_24": "fix-iam_password_policy.tf",
    "iam_password_policy_symbol": "fix-iam_password_policy.tf",
    "iam_password_policy_uppercase": "fix-iam_password_policy.tf",
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


def _safe_str(value) -> str:
    if value is None:
        return ""
    try:
        if pd.isna(value):
            return ""
    except Exception:
        pass
    return str(value)


def _row_values(row):
    if row is None:
        return []
    values = []
    for key in [
        "resource_arn",
        "resource_uid",
        "resource_name",
        "resource_id",
        "resource_type",
        "account_id",
    ]:
        val = _safe_str(row.get(key, ""))
        if val:
            values.append(val)
    return values


def _extract_id_from_text(text, prefix):
    if not text:
        return None
    m = re.search(rf"{re.escape(prefix)}-[0-9a-f]{{8,17}}", text)
    if m:
        return m.group(0)
    return None


def _extract_id_from_row(row, prefix):
    for val in _row_values(row):
        found = _extract_id_from_text(val, prefix)
        if found:
            return found
    return None


def _extract_s3_bucket_from_row(row):
    for val in _row_values(row):
        m = re.search(r"arn:aws:s3:::([^/]+)", val)
        if m:
            return m.group(1)
    return None


def _infer_attr_value(attr, row, resource_type=None):
    attr = (attr or "").strip()
    if not attr:
        return None
    rtype = (resource_type or "").strip()
    if rtype == "aws_iam_policy":
        for val in _row_values(row):
            m = re.search(r"arn:aws:iam::\d{12}:policy/([^/]+)", val)
            if m:
                if attr == "arn":
                    return f"\"{m.group(0)}\""
                if attr == "name":
                    return f"\"{m.group(1)}\""
        return "var.iam_policy_arn" if attr == "arn" else "var.iam_policy_name"
    if rtype == "aws_iam_role":
        for val in _row_values(row):
            m = re.search(r"arn:aws:iam::\d{12}:role/([^/]+)", val)
            if m and attr == "name":
                return f"\"{m.group(1)}\""
        if attr == "name":
            if row is not None:
                name = _safe_str(row.get("resource_name", ""))
                if name:
                    return f"\"{name}\""
            return "var.iam_role_name"
    if rtype == "aws_iam_instance_profile":
        for val in _row_values(row):
            m = re.search(r"arn:aws:iam::\d{12}:instance-profile/([^/]+)", val)
            if m and attr == "name":
                return f"\"{m.group(1)}\""
        if attr == "name":
            if row is not None:
                name = _safe_str(row.get("resource_name", ""))
                if name:
                    return f"\"{name}\""
            return "var.iam_instance_profile_name"
    if attr == "security_group_id":
        sg = _extract_id_from_row(row, "sg")
        if sg:
            return f"\"{sg}\""
        return "var.security_group_id"
    if attr == "ami":
        return "var.ami_id"
    if attr == "instance_type":
        return "var.instance_type"
    if attr == "subnet_id":
        subnet = _extract_id_from_row(row, "subnet")
        if subnet:
            return f"\"{subnet}\""
        return "var.subnet_id"
    if attr == "vpc_id":
        vpc = _extract_id_from_row(row, "vpc")
        if vpc:
            return f"\"{vpc}\""
        return "var.vpc_id"
    if attr == "network_interface_id":
        eni = _extract_id_from_row(row, "eni")
        if eni:
            return f"\"{eni}\""
        return "var.network_interface_id"
    if attr in ["bucket", "bucket_name", "s3_bucket_name"]:
        bucket = _extract_s3_bucket_from_row(row)
        if bucket:
            return f"\"{bucket}\""
        return "var.s3_bucket_name"
    if attr == "log_group_name":
        for val in _row_values(row):
            name = _extract_log_group_name_from_arn(val)
            if name:
                return f"\"{name}\""
        return "var.log_group_name"
    return f"var.{attr}"


def _fallback_stub(row, err):
    check_id = _safe_str(row.get("check_id", "unknown"))
    resource_uid = _safe_str(row.get("resource_uid", ""))
    title = _safe_str(row.get("check_title", ""))
    note = _safe_str(err)[:200].replace("\n", " ")
    return (
        f'# TODO: Manual remediation required for {check_id}\n'
        f'# Title: {title}\n'
        f'# Last validation error: {note}\n'
        f'resource "null_resource" "remediation_{_sanitize_label(check_id)}" {{\n'
        f'  triggers = {{\n'
        f'    check_id     = "{check_id}"\n'
        f'    resource_uid = "{resource_uid}"\n'
        f'  }}\n'
        f'}}\n'
    )


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
        m = re.search(r"<<-?\s*([A-Za-z0-9_]+)\s*$", line)
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
            m = re.search(r"<<-?\s*([A-Za-z0-9_]+)\s*$", line)
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
        m = re.search(r"<<-?\s*([A-Za-z0-9_]+)\s*$", line)  # heredoc 시작 패턴
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
            m = re.match(r'^\s*([A-Za-z0-9_]+)\s*=\s*<<-?\s*([A-Za-z0-9_]+)\s*$', line)  # heredoc 시작 감지
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
        m = re.search(r"<<-?\s*([A-Za-z0-9_]+)\s*$", line)  # heredoc 시작 감지
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
def _balance_parens_brackets(lines):
    # 괄호/대괄호 균형 보정 (미닫힘 완화)
    out = []  # 출력 라인 버퍼
    paren = 0  # 소괄호 카운터
    bracket = 0  # 대괄호 카운터
    in_heredoc = False  # heredoc 내부 여부
    heredoc_marker = None  # heredoc 종료 마커
    for line in lines:  # 라인 순회
        if in_heredoc:  # heredoc 내부면
            out.append(line)  # 그대로 추가
            if line.strip() == heredoc_marker:  # 종료 마커면
                in_heredoc = False  # heredoc 종료
                heredoc_marker = None  # 마커 초기화
            continue  # 다음 라인으로
        m = re.search(r"<<-?\s*([A-Za-z0-9_]+)\s*$", line)  # heredoc 시작 감지
        if m:  # heredoc 시작이면
            in_heredoc = True  # heredoc 진입
            heredoc_marker = m.group(1)  # 종료 마커 저장
            out.append(line)  # 라인 추가
            continue  # 다음 라인으로
        safe_line = re.sub(r'"([^"\\]|\\.)*"', '""', line)  # 문자열 내부 괄호 제거
        paren += safe_line.count("(") - safe_line.count(")")  # 소괄호 균형 갱신
        bracket += safe_line.count("[") - safe_line.count("]")  # 대괄호 균형 갱신
        out.append(line)  # 라인 추가
    if paren > 0:  # 소괄호가 부족하면
        out.extend([")"] * paren)  # 닫는 소괄호 추가
    if bracket > 0:  # 대괄호가 부족하면
        out.extend(["]"] * bracket)  # 닫는 대괄호 추가
    return out  # 결과 반환


def _repair_unbalanced_quotes(lines):
    # 따옴표 개수가 홀수인 라인을 보정하여 파싱 오류 완화
    out = []  # 출력 라인 버퍼
    in_heredoc = False  # heredoc 내부 여부
    heredoc_marker = None  # heredoc 종료 마커
    for line in lines:  # 라인 순회
        if in_heredoc:  # heredoc 내부면
            out.append(line)  # 그대로 추가
            if line.strip() == heredoc_marker:  # 종료 마커면
                in_heredoc = False  # heredoc 종료
                heredoc_marker = None  # 마커 초기화
            continue  # 다음 라인으로
        m = re.search(r"<<-?\s*([A-Za-z0-9_]+)\s*$", line)  # heredoc 시작 감지
        if m:  # heredoc 시작이면
            in_heredoc = True  # heredoc 진입
            heredoc_marker = m.group(1)  # 종료 마커 저장
            out.append(line)  # 라인 추가
            continue  # 다음 라인으로
        # 따옴표 개수 계산 (간단 휴리스틱)
        quote_count = line.count('"')  # 이중 따옴표 개수
        if quote_count % 2 == 1:  # 홀수면 미닫힘으로 판단
            out.append(line + '"')  # 닫는 따옴표 추가
            continue  # 다음 라인으로
        out.append(line)  # 정상 라인 유지
    return out  # 결과 반환


def _strip_backtick_lines(lines):
    # 백틱(`)이 포함된 라인을 주석 처리하여 HCL 오류 방지
    out = []  # 출력 라인 버퍼
    in_heredoc = False  # heredoc 내부 여부
    heredoc_marker = None  # heredoc 종료 마커
    for line in lines:  # 라인 순회
        if in_heredoc:  # heredoc 내부면
            out.append(line)  # 그대로 추가
            if line.strip() == heredoc_marker:  # 종료 마커면
                in_heredoc = False  # heredoc 종료
                heredoc_marker = None  # 마커 초기화
            continue  # 다음 라인으로
        m = re.search(r"<<-?\s*([A-Za-z0-9_]+)\s*$", line)  # heredoc 시작 감지
        if m:  # heredoc 시작이면
            in_heredoc = True  # heredoc 진입
            heredoc_marker = m.group(1)  # 종료 마커 저장
            out.append(line)  # 라인 추가
            continue  # 다음 라인으로
        if '`' in line and not line.lstrip().startswith("#"):  # 백틱 포함 + 주석 아님
            out.append("# " + line)  # 주석 처리
            continue  # 다음 라인으로
        out.append(line)  # 정상 라인 유지
    return out  # 결과 반환


def _strip_deprecated_s3_bucket_attrs(lines):
    """aws_s3_bucket 리소스에서 deprecated된 acl, server_side_encryption_configuration 제거.

    AWS provider v4+ 에서는 별도 리소스(aws_s3_bucket_acl,
    aws_s3_bucket_server_side_encryption_configuration)를 사용해야 한다.
    """
    out = []
    in_s3_bucket = False
    in_deprecated_block = False
    brace = 0
    dep_brace = 0
    in_heredoc = False
    heredoc_marker = None
    for line in lines:
        # heredoc 내부는 그대로 유지
        if in_heredoc:
            out.append(line)
            if line.strip() == heredoc_marker:
                in_heredoc = False
                heredoc_marker = None
            continue
        hm = re.search(r"<<-?\s*([A-Za-z0-9_]+)\s*$", line)
        if hm:
            in_heredoc = True
            heredoc_marker = hm.group(1)
            if not in_deprecated_block:
                out.append(line)
            continue
        # aws_s3_bucket 리소스 블록 시작 감지
        if not in_s3_bucket:
            m = re.match(r'^\s*resource\s+"aws_s3_bucket"\s+"[^"]+"\s*\{', line)
            if m:
                in_s3_bucket = True
                brace = _brace_delta(line)
                out.append(line)
                continue
        if in_s3_bucket:
            # deprecated nested block 내부 처리
            if in_deprecated_block:
                dep_brace += _brace_delta(line)
                if dep_brace <= 0:
                    in_deprecated_block = False
                # deprecated block 라인은 모두 제거
                brace += _brace_delta(line)
                if brace <= 0:
                    in_s3_bucket = False
                continue
            # acl = "..." 라인 제거
            if re.match(r'^\s*acl\s*=', line):
                brace += _brace_delta(line)
                if brace <= 0:
                    in_s3_bucket = False
                continue
            # server_side_encryption_configuration 블록 시작 → deprecated block 진입
            if re.match(r'^\s*server_side_encryption_configuration\s*\{', line):
                in_deprecated_block = True
                dep_brace = _brace_delta(line)
                brace += _brace_delta(line)
                if dep_brace <= 0:
                    in_deprecated_block = False
                if brace <= 0:
                    in_s3_bucket = False
                continue
            brace += _brace_delta(line)
            out.append(line)
            if brace <= 0:
                in_s3_bucket = False
            continue
        out.append(line)
    return out


def _remove_duplicate_data_blocks(lines):
    """검증/apply 프레임워크가 이미 제공하는 data 블록 제거.

    00-data.tf에서 aws_caller_identity, aws_region, aws_partition이 자동 제공되므로
    생성 코드에 중복으로 들어가면 충돌한다.
    """
    FRAMEWORK_DATA = {
        ("aws_caller_identity", "current"),
        ("aws_region", "current"),
        ("aws_partition", "current"),
    }
    out = []
    skip_block = False
    brace = 0
    for line in lines:
        if not skip_block:
            m = re.match(r'^\s*data\s+"([^"]+)"\s+"([^"]+)"\s*\{', line)
            if m and (m.group(1), m.group(2)) in FRAMEWORK_DATA:
                skip_block = True
                brace = _brace_delta(line)
                if brace <= 0:
                    skip_block = False
                continue
        if skip_block:
            brace += _brace_delta(line)
            if brace <= 0:
                skip_block = False
            continue
        out.append(line)
    return out


def _extract_log_group_name_from_arn(value: str) -> str | None:
    if not value or not value.startswith("arn:aws:logs:"):
        return None
    if ":log-group:" not in value:
        return None
    name = value.split(":log-group:", 1)[1]
    # Remove known suffixes
    for suffix in [":log-stream:", ":*"]:
        if suffix in name:
            name = name.split(suffix, 1)[0]
    name = name.strip()
    return name or None


def _fix_log_group_name_arn(lines):
    # log_group_name에 ARN이 들어간 경우 로그 그룹 이름으로 치환
    out = []  # 출력 라인 버퍼
    for line in lines:  # 라인 순회
        m = re.match(r'^\s*log_group_name\s*=\s*"([^"]+)"\s*$', line)  # log_group_name 라인 감지
        if m:  # 매칭되면
            value = m.group(1)  # 값 추출
            if value.startswith("arn:aws:logs:"):
                name = _extract_log_group_name_from_arn(value)
                indent = re.match(r'^(\s*)', line).group(1)  # 들여쓰기 추출
                if name:
                    out.append(f'{indent}log_group_name = "{name}"')  # 이름으로 치환
                else:
                    # ARN인데 로그 그룹 이름을 추출할 수 없으면 유효한 이름 placeholder로 대체
                    out.append(f'{indent}log_group_name = "YOUR_LOG_GROUP_NAME"')
                continue  # 다음 라인으로
        out.append(line)  # 변경 없음
    return out  # 결과 반환


def _fix_data_cloudwatch_log_group_name_arn(lines):
    # data "aws_cloudwatch_log_group"의 name에 ARN이 들어간 경우 이름으로 치환
    out = []
    in_block = False
    brace = 0
    for line in lines:
        if not in_block:
            m = re.match(r'^(\s*)data\s+"aws_cloudwatch_log_group"\s+"[^"]+"\s*\{', line)
            if m:
                in_block = True
                brace = _brace_delta(line)
                out.append(line)
                continue
            out.append(line)
            continue
        # block 내부
        m = re.match(r'^(\s*)name\s*=\s*"([^"]+)"\s*$', line)
        if m:
            value = m.group(2)
            if value.startswith("arn:aws:logs:"):
                name = _extract_log_group_name_from_arn(value)
                indent = m.group(1)
                if name:
                    out.append(f'{indent}name = "{name}"')
                else:
                    out.append(f'{indent}name = "YOUR_LOG_GROUP_NAME"')
                brace += _brace_delta(line)
                if brace <= 0:
                    in_block = False
                continue
        out.append(line)
        brace += _brace_delta(line)
        if brace <= 0:
            in_block = False
    return out


def _ensure_metric_transformation(lines):
    # aws_cloudwatch_log_metric_filter에 metric_transformation 블록이 없으면 추가
    out = []
    in_block = False
    brace = 0
    has_metric = False
    block_indent = ""
    for line in lines:
        if not in_block:
            m = re.match(r'^(\s*)resource\s+"aws_cloudwatch_log_metric_filter"\s+"[^"]+"\s*\{', line)
            if m:
                in_block = True
                brace = _brace_delta(line)
                has_metric = False
                block_indent = m.group(1)
            out.append(line)
            continue

        next_brace = brace + _brace_delta(line)
        if re.match(r'^\s*metric_transformation\s*\{', line):
            has_metric = True

        if next_brace <= 0:
            if not has_metric:
                indent = block_indent + "  "
                out.append(f"{indent}metric_transformation {{")
                out.append(f"{indent}  name      = \"RemediationMetric\"")
                out.append(f"{indent}  namespace = \"Remediation/Security\"")
                out.append(f"{indent}  value     = \"1\"")
                out.append(f"{indent}}}")
            out.append(line)
            in_block = False
            brace = 0
            continue

        out.append(line)
        brace = next_brace
    return out


def _lift_resources_from_data_blocks(lines):
    # data 블록 내부에 중첩된 resource 블록을 최상위로 이동
    out = []
    lifted = []
    in_data = False
    data_brace = 0
    in_lift = False
    lift_brace = 0
    for line in lines:
        if in_lift:
            lifted.append(line)
            lift_brace += _brace_delta(line)
            if lift_brace <= 0:
                in_lift = False
            continue
        if not in_data:
            m = re.match(r'^\s*data\s+"[^"]+"\s+"[^"]+"\s*\{', line)
            if m:
                in_data = True
                data_brace = _brace_delta(line)
                out.append(line)
                if data_brace <= 0:
                    in_data = False
                continue
            out.append(line)
            continue
        # data 블록 내부
        if re.match(r'^\s*resource\s+"[^"]+"\s+"[^"]+"\s*\{', line):
            in_lift = True
            lift_brace = _brace_delta(line)
            lifted.append(line)
            if lift_brace <= 0:
                in_lift = False
            continue
        out.append(line)
        data_brace += _brace_delta(line)
        if data_brace <= 0:
            in_data = False
    if lifted:
        out.append("")
        out.extend(lifted)
    return out


def _ensure_sns_topic_policy_arn(lines):
    # aws_sns_topic_policy에 arn이 없으면 자동 삽입
    sns_resource = None
    sns_data = None
    for line in lines:
        m = re.match(r'^\s*resource\s+"aws_sns_topic"\s+"([^"]+)"\s*\{', line)
        if m:
            sns_resource = m.group(1)
            break
    if not sns_resource:
        for line in lines:
            m = re.match(r'^\s*data\s+"aws_sns_topic"\s+"([^"]+)"\s*\{', line)
            if m:
                sns_data = m.group(1)
                break
    if sns_resource:
        arn_expr = f"aws_sns_topic.{sns_resource}.arn"
    elif sns_data:
        arn_expr = f"data.aws_sns_topic.{sns_data}.arn"
    else:
        arn_expr = "var.sns_topic_arn"

    out = []
    in_block = False
    brace = 0
    has_arn = False
    block_indent = ""
    for line in lines:
        if not in_block:
            m = re.match(r'^\s*resource\s+"aws_sns_topic_policy"\s+"[^"]+"\s*\{', line)
            if m:
                in_block = True
                brace = _brace_delta(line)
                has_arn = False
                block_indent = re.match(r'^(\s*)', line).group(1)
            out.append(line)
            continue
        next_brace = brace + _brace_delta(line)
        if re.match(r'^\s*arn\s*=', line):
            has_arn = True
        if next_brace <= 0:
            if not has_arn:
                indent = block_indent + "  "
                out.append(f"{indent}arn = {arn_expr}")
            out.append(line)
            in_block = False
            brace = 0
            continue
        out.append(line)
        brace = next_brace
    return out


def _ensure_kms_key_policy_key_id(lines):
    # aws_kms_key_policy에 key_id가 없으면 자동 삽입
    kms_resource = None
    kms_data = None
    for line in lines:
        m = re.match(r'^\s*resource\s+"aws_kms_key"\s+"([^"]+)"\s*\{', line)
        if m:
            kms_resource = m.group(1)
            break
    if not kms_resource:
        for line in lines:
            m = re.match(r'^\s*data\s+"aws_kms_key"\s+"([^"]+)"\s*\{', line)
            if m:
                kms_data = m.group(1)
                break
    if kms_resource:
        key_expr = f"aws_kms_key.{kms_resource}.key_id"
    elif kms_data:
        key_expr = f"data.aws_kms_key.{kms_data}.key_id"
    else:
        key_expr = "var.kms_key_id"

    out = []
    in_block = False
    brace = 0
    has_key = False
    block_indent = ""
    for line in lines:
        if not in_block:
            m = re.match(r'^\s*resource\s+"aws_kms_key_policy"\s+"[^"]+"\s*\{', line)
            if m:
                in_block = True
                brace = _brace_delta(line)
                has_key = False
                block_indent = re.match(r'^(\s*)', line).group(1)
            out.append(line)
            continue
        next_brace = brace + _brace_delta(line)
        if re.match(r'^\s*key_id\s*=', line):
            has_key = True
        if next_brace <= 0:
            if not has_key:
                indent = block_indent + "  "
                out.append(f"{indent}key_id = {key_expr}")
            out.append(line)
            in_block = False
            brace = 0
            continue
        out.append(line)
        brace = next_brace
    return out


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
        m = re.search(r"<<-?\s*([A-Za-z0-9_]+)\s*$", line)
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


def _convert_iam_resources_to_data(lines):
    """IAM 리소스 생성이 금지된 경우 resource → data로 전환."""
    if ALLOW_IAM_CREATE:
        return lines
    IAM_TYPES = {
        "aws_iam_policy",
        "aws_iam_role",
        "aws_iam_instance_profile",
    }
    out = []
    for line in lines:
        m = re.match(r'^(\s*)resource\s+"([^"]+)"\s+"([^"]+)"\s*\{', line)
        if m and m.group(2) in IAM_TYPES:
            indent, rtype, name = m.group(1), m.group(2), m.group(3)
            out.append(f'{indent}data "{rtype}" "{name}" {{')
            continue
        out.append(line)
    return out


def _strip_iam_resource_only_attrs(lines):
    """data IAM 블록에서 resource 전용 속성 제거."""
    if ALLOW_IAM_CREATE:
        return lines
    REMOVE_ATTRS = {
        "aws_iam_policy": {
            "policy",
            "description",
            "path",
            "tags",
        },
        "aws_iam_role": {
            "assume_role_policy",
            "managed_policy_arns",
            "inline_policy",
            "permissions_boundary",
            "max_session_duration",
            "force_detach_policies",
            "path",
            "tags",
        },
        "aws_iam_instance_profile": {
            "role",
            "path",
            "tags",
        },
    }
    out = []
    in_block = False
    brace = 0
    current_type = None
    for line in lines:
        if not in_block:
            m = re.match(r'^\s*data\s+"([^"]+)"\s+"[^"]+"\s*\{', line)
            if m and m.group(1) in REMOVE_ATTRS:
                in_block = True
                current_type = m.group(1)
                brace = _brace_delta(line)
                out.append(line)
                continue
            out.append(line)
            continue
        next_brace = brace + _brace_delta(line)
        remove_set = REMOVE_ATTRS.get(current_type, set())
        if any(re.match(rf'^\s*{re.escape(attr)}\s*=', line) for attr in remove_set):
            brace = next_brace
            if next_brace <= 0:
                in_block = False
                current_type = None
            continue
        out.append(line)
        brace = next_brace
        if brace <= 0:
            in_block = False
            current_type = None
    return out


def _ensure_iam_data_required_attrs(lines):
    """IAM data 소스에 필수 인자(name/arn) 자동 삽입."""
    if ALLOW_IAM_CREATE:
        return lines
    REQUIRED = {
        "aws_iam_policy": ("arn", "var.iam_policy_arn"),
        "aws_iam_role": ("name", "var.iam_role_name"),
        "aws_iam_instance_profile": ("name", "var.iam_instance_profile_name"),
    }
    out = []
    in_block = False
    brace = 0
    current_type = None
    has_attr = False
    insert_idx = -1
    block_indent = ""
    for line in lines:
        if not in_block:
            m = re.match(r'^\s*data\s+"([^"]+)"\s+"[^"]+"\s*\{', line)
            if m and m.group(1) in REQUIRED:
                in_block = True
                current_type = m.group(1)
                brace = _brace_delta(line)
                has_attr = False
                insert_idx = len(out)
                block_indent = re.match(r'^(\s*)', line).group(1)
                out.append(line)
                continue
            out.append(line)
            continue
        attr, value = REQUIRED.get(current_type, (None, None))
        if attr and re.match(rf'^\s*{re.escape(attr)}\s*=', line):
            has_attr = True
        next_brace = brace + _brace_delta(line)
        if next_brace <= 0:
            if not has_attr and insert_idx >= 0 and attr:
                out.insert(insert_idx + 1, f"{block_indent}  {attr} = {value}")
            out.append(line)
            in_block = False
            current_type = None
            brace = 0
            continue
        out.append(line)
        brace = next_brace
    return out


# AWS 계정 ID 패턴 (12자리 숫자, ARN 내부에서만 매칭)
_ACCOUNT_ID_RE = re.compile(r"(?<=:)\d{12}(?=:)")


def _replace_hardcoded_account_id(lines):
    """ARN 문자열 내 하드코딩된 12자리 AWS 계정 ID를 data source 참조로 치환."""
    out = []
    in_heredoc = False
    heredoc_marker = None
    for line in lines:
        if in_heredoc:
            out.append(line)
            if line.strip() == heredoc_marker:
                in_heredoc = False
                heredoc_marker = None
            continue
        hm = re.search(r"<<-?\s*([A-Za-z0-9_]+)\s*$", line)
        if hm:
            in_heredoc = True
            heredoc_marker = hm.group(1)
            out.append(line)
            continue
        # 주석 라인은 건너뜀
        stripped = line.lstrip()
        if stripped.startswith("#") or stripped.startswith("//"):
            out.append(line)
            continue
        # ARN 패턴 내 12자리 계정 ID 치환
        if "arn:aws" in line and _ACCOUNT_ID_RE.search(line):
            line = _ACCOUNT_ID_RE.sub(
                "${data.aws_caller_identity.current.account_id}", line
            )
        out.append(line)
    return out


def _replace_hardcoded_region_in_arns(lines):
    """ARN 문자열 내 하드코딩된 리전을 data source 참조로 치환."""
    out = []
    in_heredoc = False
    heredoc_marker = None
    for line in lines:
        if in_heredoc:
            out.append(line)
            if line.strip() == heredoc_marker:
                in_heredoc = False
                heredoc_marker = None
            continue
        hm = re.search(r"<<-?\s*([A-Za-z0-9_]+)\s*$", line)
        if hm:
            in_heredoc = True
            heredoc_marker = hm.group(1)
            out.append(line)
            continue
        stripped = line.lstrip()
        if stripped.startswith("#") or stripped.startswith("//"):
            out.append(line)
            continue
        if "arn:aws" in line:
            line = re.sub(
                r"(arn:aws[^:]*:)([a-z]{2}-[a-z]+-\d)(?=:)",
                r"\1${data.aws_region.current.name}",
                line,
            )
        out.append(line)
    return out


# 하드코딩된 placeholder ID 패턴
_PLACEHOLDER_PATTERNS = [
    # vpc-0123456789abcdef 스타일 placeholder
    (re.compile(r'"vpc-0123456789[a-f0-9]*"'), "var.vpc_id"),
    # subnet-0123456789abcdef 스타일 placeholder
    (re.compile(r'"subnet-0123456789[a-f0-9]*"'), "var.subnet_id"),
    # sg-0123456789abcdef 스타일 placeholder
    (re.compile(r'"sg-0123456789[a-f0-9]*"'), "var.security_group_id"),
]

# 리스트 내부 placeholder (여러 개)
_PLACEHOLDER_SUBNET_LIST_RE = re.compile(
    r'\[\s*"subnet-0123456789[a-f0-9]*"'
    r'(?:\s*,\s*"subnet-0123456789[a-f0-9]*")*\s*\]'
)


def _replace_placeholder_ids(lines):
    """하드코딩된 placeholder VPC/subnet/SG ID를 variable 참조로 치환.

    실제 AWS 리소스 ID(vpc-0565... 등)가 아닌 0123456789 패턴의
    placeholder만 치환한다.
    """
    out = []
    has_vpc_var = False
    has_subnet_var = False
    has_sg_var = False
    for line in lines:
        stripped = line.lstrip()
        if stripped.startswith("#") or stripped.startswith("//"):
            out.append(line)
            continue
        # 서브넷 리스트 패턴 (["subnet-...", "subnet-..."]) → var.subnet_ids
        if _PLACEHOLDER_SUBNET_LIST_RE.search(line):
            line = _PLACEHOLDER_SUBNET_LIST_RE.sub("var.subnet_ids", line)
            has_subnet_var = True
            out.append(line)
            continue
        for pat, replacement in _PLACEHOLDER_PATTERNS:
            if pat.search(line):
                line = pat.sub(replacement, line)
                if "vpc_id" in replacement:
                    has_vpc_var = True
                elif "subnet_id" in replacement:
                    has_subnet_var = True
                elif "security_group_id" in replacement:
                    has_sg_var = True
        out.append(line)

    # 사용된 variable 블록 추가
    var_blocks = []
    if has_vpc_var:
        var_blocks.append(
            'variable "vpc_id" {\n'
            '  description = "Target VPC ID"\n'
            '  type        = string\n'
            "}"
        )
    if has_subnet_var:
        var_blocks.append(
            'variable "subnet_id" {\n'
            '  description = "Target subnet ID"\n'
            '  type        = string\n'
            '  default     = ""\n'
            "}"
        )
        var_blocks.append(
            'variable "subnet_ids" {\n'
            '  description = "Target subnet IDs"\n'
            '  type        = list(string)\n'
            '  default     = []\n'
            "}"
        )
    if has_sg_var:
        var_blocks.append(
            'variable "security_group_id" {\n'
            '  description = "Target security group ID"\n'
            '  type        = string\n'
            '  default     = ""\n'
            "}"
        )
    if var_blocks:
        out.append("")
        for vb in var_blocks:
            out.extend(vb.splitlines())
            out.append("")
    return out


def _fix_deprecated_resource_types(lines):
    """Deprecated/invalid 리소스 타입을 올바른 타입으로 치환."""
    # data source 이름 변경 (AWS provider v4+)
    DEPRECATED_DATA_SOURCES = {
        "aws_subnet_ids": "aws_subnets",
    }
    # 잘못된 resource 타입 → 올바른 타입
    INVALID_RESOURCE_TYPES = {
        "aws_instance_profile_attachment": "aws_iam_instance_profile",
        "aws_ec2_instance_profile": "aws_iam_instance_profile",
    }
    out = []
    for line in lines:
        # data source 타입 치환
        for old_type, new_type in DEPRECATED_DATA_SOURCES.items():
            if f'"{old_type}"' in line:
                line = line.replace(f'"{old_type}"', f'"{new_type}"')
                # 참조도 치환 (data.aws_subnet_ids → data.aws_subnets)
            if f"data.{old_type}." in line:
                line = line.replace(f"data.{old_type}.", f"data.{new_type}.")
        # resource 타입 치환
        for old_type, new_type in INVALID_RESOURCE_TYPES.items():
            if f'"{old_type}"' in line:
                line = line.replace(f'"{old_type}"', f'"{new_type}"')
            if f"{old_type}." in line:
                line = line.replace(f"{old_type}.", f"{new_type}.")
        out.append(line)
    return out


def _fix_set_indexing(lines):
    """Set 타입 속성에 인덱스 접근([0])을 tolist() 호출로 수정."""
    # vpc_security_group_ids[0] → tolist(xxx.vpc_security_group_ids)[0]
    SET_ATTRS = {
        "vpc_security_group_ids",
        "security_groups",
    }
    out = []
    for line in lines:
        for attr in SET_ATTRS:
            # data.xxx.yyy.attr[N] 패턴 수정
            pat = re.compile(
                rf'((?:data\.\w+\.\w+|aws_\w+\.\w+)\.{attr})\[(\d+)\]'
            )
            if pat.search(line):
                line = pat.sub(r'tolist(\1)[\2]', line)
        out.append(line)
    return out


def _ensure_visibility_config(lines):
    """aws_wafv2_web_acl 리소스에 visibility_config 블록이 없으면 추가."""
    out = []
    in_block = False
    brace = 0
    has_visibility = False
    block_indent = ""
    for line in lines:
        if not in_block:
            m = re.match(
                r'^(\s*)resource\s+"aws_wafv2_web_acl"\s+"[^"]+"\s*\{', line
            )
            if m:
                in_block = True
                brace = _brace_delta(line)
                has_visibility = False
                block_indent = m.group(1)
            out.append(line)
            continue

        next_brace = brace + _brace_delta(line)
        if re.match(r'^\s*visibility_config\s*\{', line):
            has_visibility = True

        if next_brace <= 0:
            if not has_visibility:
                indent = block_indent + "  "
                out.append(f"{indent}visibility_config {{")
                out.append(f'{indent}  cloudwatch_metrics_enabled = true')
                out.append(f'{indent}  metric_name               = "remediation-waf-metric"')
                out.append(f'{indent}  sampled_requests_enabled   = true')
                out.append(f"{indent}}}")
            out.append(line)
            in_block = False
            brace = 0
            continue

        out.append(line)
        brace = next_brace
    return out


def _ensure_cloudwatch_alarm_required_attrs(lines):
    """aws_cloudwatch_metric_alarm에 evaluation_periods 누락 시 기본값 추가."""
    out = []
    in_alarm = False
    alarm_brace = 0
    has_eval_periods = False
    insert_idx = -1

    for line in lines:
        if not in_alarm:
            m = re.match(
                r'^\s*resource\s+"aws_cloudwatch_metric_alarm"\s+"([^"]+)"\s*\{',
                line,
            )
            if m:
                in_alarm = True
                alarm_brace = _brace_delta(line)
                has_eval_periods = False
                insert_idx = len(out)
                out.append(line)
                if alarm_brace <= 0:
                    in_alarm = False
                continue
            out.append(line)
            continue

        if re.match(r'^\s*evaluation_periods\s*=', line):
            has_eval_periods = True

        alarm_brace += _brace_delta(line)
        out.append(line)

        if alarm_brace <= 0:
            in_alarm = False
            if not has_eval_periods and insert_idx >= 0:
                out.insert(insert_idx + 1, "  evaluation_periods = 1")
            insert_idx = -1

    return out


def _remove_dangerous_iam_attachments(lines):
    """기존 IAM 리소스를 수정하는 위험한 블록 제거.

    제거 대상:
    - aws_iam_policy_attachment (exclusive 리소스, empty result 오류)
    - aws_iam_role/user/group_policy_attachment (bootstrap 권한 밖 대상)
    - aws_iam_user_login_profile (이미 존재하는 프로필 중복 생성 오류)
    - aws_iam_access_key (기존 사용자에 키 생성 시도)
    - aws_iam_user_policy (기존 사용자에 인라인 정책)
    """
    DANGEROUS_TYPES = re.compile(
        r'^\s*resource\s+"('
        r'aws_iam_policy_attachment'
        r'|aws_iam_(?:role|user|group)_policy_attachment'
        r'|aws_iam_user_login_profile'
        r'|aws_iam_access_key'
        r'|aws_iam_user_policy'
        r')"\s+"[^"]+"\s*\{'
    )
    out = []
    skip_block = False
    brace = 0
    for line in lines:
        if not skip_block:
            if DANGEROUS_TYPES.match(line):
                skip_block = True
                brace = _brace_delta(line)
                if brace <= 0:
                    skip_block = False
                continue
            out.append(line)
            continue
        brace += _brace_delta(line)
        if brace <= 0:
            skip_block = False
        continue
    return out


def _strip_lifecycle_from_data_blocks(lines):
    """data 블록 내부의 lifecycle {} 블록 제거 (data 블록에서는 유효하지 않음)."""
    out = []
    in_data = False
    data_brace = 0
    skip_lifecycle = False
    lifecycle_brace = 0
    for line in lines:
        if not in_data:
            if re.match(r'^\s*data\s+"[^"]+"\s+"[^"]+"\s*\{', line):
                in_data = True
                data_brace = _brace_delta(line)
            out.append(line)
            continue

        if not skip_lifecycle:
            if re.match(r'^\s*lifecycle\s*\{', line):
                skip_lifecycle = True
                lifecycle_brace = _brace_delta(line)
                if lifecycle_brace <= 0:
                    skip_lifecycle = False
                data_brace += _brace_delta(line)
                if data_brace <= 0:
                    in_data = False
                continue
        if skip_lifecycle:
            lifecycle_brace += _brace_delta(line)
            data_brace += _brace_delta(line)
            if lifecycle_brace <= 0:
                skip_lifecycle = False
            if data_brace <= 0:
                in_data = False
            continue

        data_brace += _brace_delta(line)
        if data_brace <= 0:
            in_data = False
        out.append(line)
    return out


def _ensure_launch_template_id_or_name(lines):
    """aws_instance 내 launch_template 블록에 id/name 누락 시 변수 참조 추가."""
    out = []
    in_instance = False
    instance_brace = 0
    in_lt = False
    lt_brace = 0
    has_id_or_name = False
    lt_insert_idx = -1

    for line in lines:
        if not in_instance:
            if re.match(r'^\s*resource\s+"aws_instance"\s+"[^"]+"\s*\{', line):
                in_instance = True
                instance_brace = _brace_delta(line)
            out.append(line)
            continue

        if not in_lt:
            m = re.match(r'^(\s*)launch_template\s*\{', line)
            if m:
                in_lt = True
                lt_brace = _brace_delta(line)
                has_id_or_name = False
                lt_insert_idx = len(out)
                out.append(line)
                instance_brace += _brace_delta(line)
                continue
            instance_brace += _brace_delta(line)
            if instance_brace <= 0:
                in_instance = False
            out.append(line)
            continue

        if re.match(r'^\s*(id|name)\s*=', line):
            has_id_or_name = True
        lt_brace += _brace_delta(line)
        instance_brace += _brace_delta(line)
        out.append(line)

        if lt_brace <= 0:
            if not has_id_or_name and lt_insert_idx >= 0:
                out.insert(lt_insert_idx + 1, '    name = var.launch_template_name')
            in_lt = False
            lt_insert_idx = -1
        if instance_brace <= 0:
            in_instance = False
    return out


def _ensure_network_acl_vpc_id(lines):
    """aws_network_acl 리소스에 vpc_id 누락 시 변수 참조 추가."""
    out = []
    in_nacl = False
    nacl_brace = 0
    has_vpc_id = False
    insert_idx = -1

    for line in lines:
        if not in_nacl:
            m = re.match(
                r'^\s*resource\s+"aws_network_acl"\s+"[^"]+"\s*\{', line
            )
            if m:
                in_nacl = True
                nacl_brace = _brace_delta(line)
                has_vpc_id = False
                insert_idx = len(out)
                out.append(line)
                if nacl_brace <= 0:
                    in_nacl = False
                continue
            out.append(line)
            continue

        if re.match(r'^\s*vpc_id\s*=', line):
            has_vpc_id = True
        nacl_brace += _brace_delta(line)
        out.append(line)

        if nacl_brace <= 0:
            in_nacl = False
            if not has_vpc_id and insert_idx >= 0:
                out.insert(insert_idx + 1, '  vpc_id = var.vpc_id')
            insert_idx = -1
    return out


def _lift_resources_from_resource_blocks(lines):
    """resource 블록 내부에 중첩된 resource/data 블록을 최상위로 추출."""
    out = []
    lifted = []
    depth = 0  # resource 블록 중첩 깊이
    brace = 0
    in_resource = False
    inner_block_lines = []
    inner_brace = 0
    capturing_inner = False

    for line in lines:
        if not in_resource:
            m = re.match(
                r'^\s*resource\s+"[^"]+"\s+"[^"]+"\s*\{', line
            )
            if m:
                in_resource = True
                brace = _brace_delta(line)
                depth = 1
            out.append(line)
            continue

        if not capturing_inner:
            # 내부에 또 다른 resource/data 블록이 있는지 확인
            m = re.match(
                r'^\s*(resource|data)\s+"[^"]+"\s+"[^"]+"\s*\{', line
            )
            if m:
                capturing_inner = True
                inner_block_lines = [line.lstrip()]
                inner_brace = _brace_delta(line)
                brace += _brace_delta(line)
                if inner_brace <= 0:
                    capturing_inner = False
                    lifted.append("\n".join(inner_block_lines))
                    inner_block_lines = []
                continue

            brace += _brace_delta(line)
            if brace <= 0:
                in_resource = False
            out.append(line)
            continue

        inner_brace += _brace_delta(line)
        brace += _brace_delta(line)
        inner_block_lines.append(line.lstrip())
        if inner_brace <= 0:
            capturing_inner = False
            lifted.append("\n".join(inner_block_lines))
            inner_block_lines = []
        if brace <= 0:
            in_resource = False

    if lifted:
        out.append("")
        for block in lifted:
            out.extend(block.splitlines())
            out.append("")
    return out


def _ensure_lifecycle_rule_id(lines):
    """aws_s3_bucket_lifecycle_configuration의 rule 블록에 id 누락 시 기본값 추가."""
    out = []
    in_lifecycle_cfg = False
    lifecycle_brace = 0
    in_rule = False
    rule_brace = 0
    has_id = False
    rule_insert_idx = -1
    rule_counter = 0

    for line in lines:
        if not in_lifecycle_cfg:
            m = re.match(
                r'^\s*resource\s+"aws_s3_bucket_lifecycle_configuration"\s+"[^"]+"\s*\{',
                line,
            )
            if m:
                in_lifecycle_cfg = True
                lifecycle_brace = _brace_delta(line)
                rule_counter = 0
            out.append(line)
            continue

        if not in_rule:
            m = re.match(r'^(\s*)rule\s*\{', line)
            if m:
                in_rule = True
                rule_brace = _brace_delta(line)
                has_id = False
                rule_counter += 1
                rule_insert_idx = len(out)
                out.append(line)
                lifecycle_brace += _brace_delta(line)
                continue
            lifecycle_brace += _brace_delta(line)
            if lifecycle_brace <= 0:
                in_lifecycle_cfg = False
            out.append(line)
            continue

        if re.match(r'^\s*id\s*=', line):
            has_id = True
        rule_brace += _brace_delta(line)
        lifecycle_brace += _brace_delta(line)
        out.append(line)

        if rule_brace <= 0:
            if not has_id and rule_insert_idx >= 0:
                out.insert(
                    rule_insert_idx + 1,
                    f'    id = "lifecycle-rule-{rule_counter}"',
                )
            in_rule = False
            rule_insert_idx = -1
        if lifecycle_brace <= 0:
            in_lifecycle_cfg = False
    return out


def _ensure_noncurrent_days_in_lifecycle(lines):
    """noncurrent_version_expiration 블록에 noncurrent_days 누락 시 기본값 추가."""
    out = []
    in_block = False
    brace = 0
    has_days = False
    insert_idx = -1
    block_indent = ""
    for line in lines:
        if not in_block:
            m = re.match(r'^(\s*)noncurrent_version_expiration\s*\{', line)
            if m:
                in_block = True
                brace = _brace_delta(line)
                has_days = False
                insert_idx = len(out)
                block_indent = m.group(1)
                out.append(line)
                continue
            out.append(line)
            continue
        if re.match(r'^\s*noncurrent_days\s*=', line):
            has_days = True
        next_brace = brace + _brace_delta(line)
        out.append(line)
        if next_brace <= 0:
            if not has_days and insert_idx >= 0:
                out.insert(insert_idx + 1, f"{block_indent}  noncurrent_days = 90")
            in_block = False
            brace = 0
            insert_idx = -1
        else:
            brace = next_brace
    return out


def _replace_placeholder_values(lines):
    """placeholder 이메일, 키페어 등을 variable 참조로 치환."""
    REPLACEMENTS = [
        (re.compile(r'"example@example\.com"'), "var.notification_email"),
        (re.compile(r'"your-key-pair-name"'), "var.key_pair_name"),
        (re.compile(r'"YOUR_CLOUDTRAIL_LOG_GROUP_NAME"'), "var.cloudtrail_log_group_name"),
        (re.compile(r'"my-config-bucket"'), "var.config_bucket_name"),
    ]
    out = []
    used_vars = set()
    for line in lines:
        stripped = line.lstrip()
        if stripped.startswith("#") or stripped.startswith("//"):
            out.append(line)
            continue
        for pat, replacement in REPLACEMENTS:
            if pat.search(line):
                line = pat.sub(replacement, line)
                used_vars.add(replacement)
        out.append(line)

    var_defs = {
        "var.notification_email": (
            'variable "notification_email" {\n'
            '  description = "Email for alarm notifications"\n'
            '  type        = string\n'
            '  default     = "security@example.com"\n'
            "}"
        ),
        "var.key_pair_name": (
            'variable "key_pair_name" {\n'
            '  description = "EC2 key pair name"\n'
            '  type        = string\n'
            '  default     = ""\n'
            "}"
        ),
        "var.cloudtrail_log_group_name": (
            'variable "cloudtrail_log_group_name" {\n'
            '  description = "CloudTrail CloudWatch log group name"\n'
            '  type        = string\n'
            "}"
        ),
        "var.config_bucket_name": (
            'variable "config_bucket_name" {\n'
            '  description = "S3 bucket for AWS Config"\n'
            '  type        = string\n'
            "}"
        ),
    }
    if used_vars:
        out.append("")
        for var_ref in sorted(used_vars):
            if var_ref in var_defs:
                out.extend(var_defs[var_ref].splitlines())
                out.append("")
    return out


def _convert_s3_bucket_resource_to_data(lines):
    """resource "aws_s3_bucket" with hardcoded bucket names → data source.

    기존 S3 버킷을 다시 생성하면 BucketAlreadyOwnedByYou 오류가 발생하므로
    하드코딩된 버킷 이름을 가진 resource 블록을 data source로 변환한다.
    """
    # 1단계: resource "aws_s3_bucket" 블록에서 하드코딩된 버킷 이름 수집
    conversions = {}  # {resource_name: bucket_value}
    i = 0
    while i < len(lines):
        m = re.match(r'^\s*resource\s+"aws_s3_bucket"\s+"([^"]+)"\s*\{', lines[i])
        if m:
            res_name = m.group(1)
            brace = _brace_delta(lines[i])
            bucket_value = None
            j = i + 1
            while j < len(lines) and brace > 0:
                bm = re.match(r'^\s*bucket\s*=\s*"([^"]+)"', lines[j])
                if bm:
                    bucket_value = bm.group(1)
                brace += _brace_delta(lines[j])
                j += 1
            # 보간(${...})이 없는 리터럴 문자열만 변환 대상
            if bucket_value and "${" not in bucket_value:
                conversions[res_name] = bucket_value
        i += 1

    if not conversions:
        return lines

    # 2단계: resource 블록을 data 블록으로 변환하고 참조 업데이트
    out = []
    skip_block = False
    skip_brace = 0
    for line in lines:
        if skip_block:
            skip_brace += _brace_delta(line)
            if skip_brace <= 0:
                skip_block = False
            continue

        m = re.match(r'^(\s*)resource\s+"aws_s3_bucket"\s+"([^"]+)"\s*\{', line)
        if m and m.group(2) in conversions:
            res_name = m.group(2)
            indent = m.group(1)
            bucket_val = conversions[res_name]
            out.append(f'{indent}data "aws_s3_bucket" "{res_name}" {{')
            out.append(f'{indent}  bucket = "{bucket_val}"')
            out.append(f'{indent}}}')
            skip_brace = _brace_delta(line)
            if skip_brace > 0:
                skip_block = True
            continue

        # 참조 업데이트: aws_s3_bucket.name → data.aws_s3_bucket.name
        for res_name in conversions:
            line = re.sub(
                rf'(?<!data\.)aws_s3_bucket\.{re.escape(res_name)}',
                f'data.aws_s3_bucket.{res_name}',
                line,
            )
        out.append(line)

    return out


def _remove_s3_bucket_acl_resources(lines):
    """aws_s3_bucket_acl 리소스 블록 제거.

    BucketOwnerEnforced 설정된 버킷에서는 ACL을 사용할 수 없으므로
    AccessControlListNotSupported 오류를 방지한다.
    """
    out = []
    skip_block = False
    brace = 0
    for line in lines:
        if not skip_block:
            if re.match(r'^\s*resource\s+"aws_s3_bucket_acl"\s+"[^"]+"\s*\{', line):
                skip_block = True
                brace = _brace_delta(line)
                if brace <= 0:
                    skip_block = False
                continue
            out.append(line)
            continue
        brace += _brace_delta(line)
        if brace <= 0:
            skip_block = False
    return out


def _fix_mfa_delete(lines):
    """mfa_delete = "Enabled" → "Disabled" (Terraform으로 MFA 설정 불가).

    MFA 삭제는 AWS CLI에서 MFA 세션으로만 활성화할 수 있으므로
    Terraform에서 "Enabled" 설정 시 AccessDenied 오류가 발생한다.
    """
    out = []
    for line in lines:
        line = re.sub(
            r'(mfa_delete\s*=\s*)"Enabled"',
            r'\1"Disabled"',
            line,
        )
        out.append(line)
    return out


def _ensure_cloudtrail_s3_bucket_policy(lines):
    """CloudTrail 리소스가 있을 때 S3 bucket policy에 CloudTrail 권한을 보장.

    InsufficientS3BucketPolicyException 방지: CloudTrail이 S3 버킷에
    로그를 기록하려면 bucket policy에 cloudtrail.amazonaws.com 서비스
    주체의 s3:PutObject, s3:GetBucketAcl 권한이 필요하다.
    """
    # CloudTrail 리소스 존재 여부 확인
    has_cloudtrail = False
    cloudtrail_bucket_name = None
    for line in lines:
        if re.match(r'^\s*resource\s+"aws_cloudtrail"\s+"[^"]+"\s*\{', line):
            has_cloudtrail = True
        m = re.match(r'^\s*s3_bucket_name\s*=\s*"([^"]+)"', line)
        if m and has_cloudtrail:
            cloudtrail_bucket_name = m.group(1)

    if not has_cloudtrail or not cloudtrail_bucket_name:
        return lines

    # 이미 bucket policy가 있으면 건너뜀
    for line in lines:
        if re.match(r'^\s*resource\s+"aws_s3_bucket_policy"\s+"[^"]+"\s*\{', line):
            return lines

    # CloudTrail용 S3 bucket policy 추가
    bucket_arn = f"arn:aws:s3:::{cloudtrail_bucket_name}"
    POLICY_TEMPLATE = [
        '',
        'resource "aws_s3_bucket_policy" "remediation_cloudtrail_bucket_policy" {',
        f'  bucket = "{cloudtrail_bucket_name}"',
        '  policy = jsonencode({',
        '    Version = "2012-10-17"',
        '    Statement = [',
        '      {',
        '        Sid       = "AWSCloudTrailAclCheck"',
        '        Effect    = "Allow"',
        '        Principal = { Service = "cloudtrail.amazonaws.com" }',
        '        Action    = "s3:GetBucketAcl"',
        f'        Resource  = "{bucket_arn}"',
        '      },',
        '      {',
        '        Sid       = "AWSCloudTrailWrite"',
        '        Effect    = "Allow"',
        '        Principal = { Service = "cloudtrail.amazonaws.com" }',
        '        Action    = "s3:PutObject"',
        f'        Resource  = "{bucket_arn}/*"',
        '        Condition = {',
        '          StringEquals = {',
        '            "s3:x-amz-acl" = "bucket-owner-full-control"',
        '          }',
        '        }',
        '      }',
        '    ]',
        '  })',
        '}',
    ]
    lines.extend(POLICY_TEMPLATE)
    return lines


def _fix_unsupported_data_attrs(lines):
    """data source에서 지원하지 않는 속성 참조를 variable로 치환.

    예: data.aws_instance.*.vpc_id → var.vpc_id (aws_instance는 vpc_id를 export하지 않음)
    """
    # data.aws_instance.<name>.vpc_id → var.vpc_id
    out = []
    for line in lines:
        stripped = line.lstrip()
        if stripped.startswith("#") or stripped.startswith("//"):
            out.append(line)
            continue
        line = re.sub(
            r'data\.aws_instance\.\w+\.vpc_id',
            'var.vpc_id',
            line,
        )
        # data.aws_subnets.<name>.vpc_id / data.aws_security_groups.<name>.vpc_id → var.vpc_id
        line = re.sub(
            r'data\.aws_subnets\.\w+\.vpc_id',
            'var.vpc_id',
            line,
        )
        line = re.sub(
            r'data\.aws_security_groups\.\w+\.vpc_id',
            'var.vpc_id',
            line,
        )
        # data.aws_instance.<name>.primary_network_interface_id → var.network_interface_id
        line = re.sub(
            r'data\.aws_instance\.\w+\.primary_network_interface_id',
            'var.network_interface_id',
            line,
        )
        # data.aws_instance.<name>.launch_time (string) used in math → 0
        line = re.sub(
            r'data\.aws_instance\.\w+\.launch_time',
            '0',
            line,
        )
        # data.aws_date_time.<name>.<attr> → 0 (unsupported data source)
        line = re.sub(
            r'data\.aws_date_time\.\w+\.\w+',
            '0',
            line,
        )
        out.append(line)
    return out


def _ensure_required_resource_attrs(lines):
    """여러 리소스 타입에서 자주 누락되는 필수 속성을 자동 삽입."""
    # 1차 패스: 기존 리소스 이름 수집 (cross-reference용)
    existing_resources = {}
    for line in lines:
        m = re.match(r'^\s*resource\s+"([^"]+)"\s+"([^"]+)"\s*\{', line)
        if m:
            existing_resources.setdefault(m.group(1), []).append(m.group(2))

    # 리소스별 필수 속성 정의: {attr: default_value}
    # 값이 callable이면 existing_resources를 인자로 호출
    REQUIRED = {
        "aws_iam_role": {
            "assume_role_policy": (
                'jsonencode({\n'
                '    Version = "2012-10-17"\n'
                '    Statement = [{\n'
                '      Action = "sts:AssumeRole"\n'
                '      Effect = "Allow"\n'
                '      Principal = { Service = "ec2.amazonaws.com" }\n'
                '    }]\n'
                '  })'
            ),
        },
        "aws_cloudtrail": {
            "name": '"remediation-cloudtrail"',
            "s3_bucket_name": '"remediation-cloudtrail-bucket"',
        },
        "aws_inspector_assessment_target": {
            "name": '"remediation-inspector-target"',
        },
        "aws_inspector_assessment_template": {
            "name": '"remediation-inspector-template"',
            "duration": "3600",
        },
        "aws_config_configuration_recorder": {
            "name": '"remediation-config-recorder"',
        },
        "aws_ssm_activation": {
            "iam_role": "var.ssm_iam_role",
        },
        "aws_network_interface_sg_attachment": {
            "security_group_id": "var.security_group_id",
            "network_interface_id": "var.network_interface_id",
        },
        "aws_s3_bucket_lifecycle_configuration": {
            "bucket": "var.s3_bucket_name",
        },
        "aws_instance": {
            "ami": "var.ami_id",
            "instance_type": "var.instance_type",
        },
    }

    # inspector_assessment_template의 target_arn: 기존 target 리소스가 있으면 참조
    if "aws_inspector_assessment_target" in existing_resources:
        target_name = existing_resources["aws_inspector_assessment_target"][0]
        REQUIRED["aws_inspector_assessment_template"]["target_arn"] = (
            f"aws_inspector_assessment_target.{target_name}.arn"
        )
    else:
        REQUIRED["aws_inspector_assessment_template"]["target_arn"] = (
            "var.inspector_target_arn"
        )

    # cloudtrail의 s3_bucket_name: 기존 S3 bucket 리소스가 있으면 참조
    if "aws_s3_bucket" in existing_resources:
        bucket_name = existing_resources["aws_s3_bucket"][0]
        REQUIRED["aws_cloudtrail"]["s3_bucket_name"] = (
            f"aws_s3_bucket.{bucket_name}.id"
        )

    out = []
    current_type = None
    in_block = False
    brace = 0
    found_attrs = set()
    insert_idx = -1

    for line in lines:
        if not in_block:
            m = re.match(r'^\s*resource\s+"([^"]+)"\s+"[^"]+"\s*\{', line)
            if m and m.group(1) in REQUIRED:
                current_type = m.group(1)
                in_block = True
                brace = _brace_delta(line)
                found_attrs = set()
                insert_idx = len(out)
                out.append(line)
                if brace <= 0:
                    in_block = False
                continue
            out.append(line)
            continue

        # 속성 존재 여부 확인
        for attr in REQUIRED[current_type]:
            if re.match(rf'^\s*{re.escape(attr)}\s*=', line):
                found_attrs.add(attr)
        brace += _brace_delta(line)
        out.append(line)

        if brace <= 0:
            # 블록 종료 시 누락 속성 삽입
            missing = set(REQUIRED[current_type].keys()) - found_attrs
            if missing and insert_idx >= 0:
                for i, attr in enumerate(sorted(missing)):
                    val = REQUIRED[current_type][attr]
                    out.insert(insert_idx + 1 + i, f"  {attr} = {val}")
            in_block = False
            insert_idx = -1
    return out


def _ensure_default_vpc_data(lines):
    """data.aws_vpc.default 참조가 있으면 data 블록을 자동 추가."""
    has_ref = any("data.aws_vpc.default" in line for line in lines)
    if not has_ref:
        return lines
    has_block = any(re.match(r'^\s*data\s+"aws_vpc"\s+"default"\s*\{', line) for line in lines)
    if has_block:
        return lines
    out = list(lines)
    out.append("")
    out.append('data "aws_vpc" "default" {')
    out.append("  default = true")
    out.append("}")
    out.append("")
    return out


def _strip_unsupported_data_sources(lines):
    """지원하지 않는 data source 블록 제거."""
    UNSUPPORTED = {"aws_date_time"}
    out = []
    in_block = False
    brace = 0
    current_type = None
    for line in lines:
        if not in_block:
            m = re.match(r'^\s*data\s+"([^"]+)"\s+"[^"]+"\s*\{', line)
            if m and m.group(1) in UNSUPPORTED:
                in_block = True
                current_type = m.group(1)
                brace = _brace_delta(line)
                if brace <= 0:
                    in_block = False
                    current_type = None
                continue
            out.append(line)
            continue
        brace += _brace_delta(line)
        if brace <= 0:
            in_block = False
            current_type = None
        continue
    return out


def _fix_time_function_assignments(lines):
    """time() 함수가 포함된 할당은 0으로 치환."""
    out = []
    for line in lines:
        if "time()" in line:
            m = re.match(r'^(\s*)([A-Za-z0-9_]+)\s*=', line)
            if m:
                indent, name = m.group(1), m.group(2)
                out.append(f"{indent}{name} = 0")
                continue
        out.append(line)
    return out


def _ensure_flow_log_target(lines):
    """aws_flow_log에 필수 대상(vpc_id/eni_id/...)이 없으면 vpc_id를 추가."""
    out = []
    in_block = False
    brace = 0
    has_target = False
    block_indent = ""
    targets = {
        "eni_id",
        "vpc_id",
        "subnet_id",
        "transit_gateway_id",
        "transit_gateway_attachment_id",
        "regional_nat_gateway_id",
    }
    for line in lines:
        if not in_block:
            m = re.match(r'^\s*resource\s+"aws_flow_log"\s+"[^"]+"\s*\{', line)
            if m:
                in_block = True
                brace = _brace_delta(line)
                has_target = False
                block_indent = re.match(r'^(\s*)', line).group(1)
                out.append(line)
                continue
            out.append(line)
            continue
        next_brace = brace + _brace_delta(line)
        for attr in targets:
            if re.match(rf'^\s*{re.escape(attr)}\s*=', line):
                has_target = True
                break
        if next_brace <= 0:
            if not has_target:
                out.append(f"{block_indent}  vpc_id = var.vpc_id")
            out.append(line)
            in_block = False
            brace = 0
            continue
        out.append(line)
        brace = next_brace
    return out


def _sanitize_invalid_name_values(lines):
    """name 속성에 허용되지 않는 문자가 있으면 안전한 값으로 치환."""
    out = []
    for line in lines:
        m = re.match(r'^(\s*)name\s*=\s*"([^"]+)"\s*$', line)
        if m:
            indent = m.group(1)
            raw = m.group(2)
            cleaned = re.sub(r"[^A-Za-z0-9_+=,.@-]", "-", raw)
            cleaned = re.sub(r"-+", "-", cleaned).strip("-")
            if cleaned:
                line = f'{indent}name = "{cleaned}"'
        out.append(line)
    return out


def _inject_required_attr(tf_code, resource_type, attr, value_expr):
    lines = tf_code.splitlines()
    out = []
    in_block = False
    brace = 0
    found = False
    insert_idx = -1
    block_indent = ""
    for line in lines:
        if not in_block:
            m = re.match(rf'^(\s*)resource\s+"{re.escape(resource_type)}"\s+"[^"]+"\s*\{{', line)
            if m:
                in_block = True
                brace = _brace_delta(line)
                found = False
                insert_idx = len(out)
                block_indent = m.group(1)
                out.append(line)
                continue
            out.append(line)
            continue
        next_brace = brace + _brace_delta(line)
        if re.match(rf'^\s*{re.escape(attr)}\s*=', line):
            found = True
        if next_brace <= 0:
            if not found and insert_idx >= 0 and value_expr:
                out.insert(insert_idx + 1, f"{block_indent}  {attr} = {value_expr}")
            out.append(line)
            in_block = False
            brace = 0
            continue
        out.append(line)
        brace = next_brace
    return "\n".join(out)


def _auto_declare_variables(lines):
    """코드에서 참조되는 var.xxx 중 선언되지 않은 variable 블록을 자동 추가."""
    # 기존 variable 선언 수집
    declared = set()
    for line in lines:
        m = re.match(r'^\s*variable\s+"([^"]+)"\s*\{', line)
        if m:
            declared.add(m.group(1))

    # var.xxx 참조 수집 (주석 제외)
    referenced = set()
    in_heredoc = False
    heredoc_marker = None
    for line in lines:
        stripped = line.lstrip()
        if in_heredoc:
            if stripped.rstrip() == heredoc_marker:
                in_heredoc = False
            continue
        hm = re.search(r'<<-?\s*([A-Z_]+)\s*$', line)
        if hm:
            in_heredoc = True
            heredoc_marker = hm.group(1)
            continue
        if stripped.startswith("#") or stripped.startswith("//"):
            continue
        for m in re.finditer(r'var\.([A-Za-z_][A-Za-z0-9_]*)', line):
            referenced.add(m.group(1))

    undeclared = referenced - declared
    if not undeclared:
        return lines

    # 변수별 기본 설명/타입 매핑
    VAR_DEFAULTS = {
        "vpc_id": ('description = "Target VPC ID"\n  type        = string', None),
        "subnet_id": ('description = "Target subnet ID"\n  type        = string\n  default     = ""', None),
        "subnet_ids": ('description = "Target subnet IDs"\n  type        = list(string)\n  default     = []', None),
        "security_group_id": ('description = "Target security group ID"\n  type        = string\n  default     = ""', None),
        "network_interface_id": ('description = "Target network interface ID"\n  type        = string\n  default     = ""', None),
        "ami_id": ('description = "AMI ID for new or managed instances"\n  type        = string\n  default     = ""', None),
        "instance_type": ('description = "EC2 instance type"\n  type        = string\n  default     = ""', None),
        "launch_template_name": ('description = "EC2 launch template name"\n  type        = string\n  default     = ""', None),
        "s3_bucket_name": ('description = "Target S3 bucket name"\n  type        = string\n  default     = ""', None),
        "log_group_name": ('description = "CloudWatch log group name"\n  type        = string\n  default     = ""', None),
        "iam_policy_arn": ('description = "Existing IAM policy ARN"\n  type        = string', None),
        "iam_policy_name": ('description = "Existing IAM policy name"\n  type        = string', None),
        "iam_role_name": ('description = "Existing IAM role name"\n  type        = string', None),
        "iam_instance_profile_name": ('description = "Existing IAM instance profile name"\n  type        = string', None),
        "ssm_iam_role": ('description = "IAM role for SSM activation"\n  type        = string', None),
        "inspector_target_arn": ('description = "Inspector assessment target ARN"\n  type        = string', None),
    }

    out = list(lines)
    out.append("")
    for var_name in sorted(undeclared):
        body = VAR_DEFAULTS.get(var_name)
        if body:
            inner = body[0]
        else:
            inner = f'description = "{var_name}"\n  type        = string\n  default     = ""'
        out.append(f'variable "{var_name}" {{')
        for bl in inner.split("\n"):
            out.append(f"  {bl.lstrip()}")
        out.append("}")
        out.append("")
    return out


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
    # deprecated/invalid 리소스 타입 수정
    lines = _fix_deprecated_resource_types(lines)
    # set 인덱싱 오류 수정
    lines = _fix_set_indexing(lines)
    # deprecated S3 bucket 속성 제거 (acl, inline encryption)
    lines = _strip_deprecated_s3_bucket_attrs(lines)
    # 프레임워크 중복 data 블록 제거
    lines = _remove_duplicate_data_blocks(lines)
    # data 블록 내부에 중첩된 resource 블록 추출
    lines = _lift_resources_from_data_blocks(lines)
    # 지원하지 않는 data source 제거
    lines = _strip_unsupported_data_sources(lines)
    # provider 스키마 기반 computed-only 속성 제거
    lines = _strip_schema_computed_attrs(lines)
    lines = _strip_unconfigurable_attrs_in_resources(lines, extra_unconfig_attrs)
    # resource/data 이름 정규화 및 참조 동기화
    lines = _normalize_block_names(lines)
    # IAM 생성 금지 시 resource → data 전환 및 필수 인자 보강
    lines = _convert_iam_resources_to_data(lines)
    lines = _strip_iam_resource_only_attrs(lines)
    lines = _ensure_iam_data_required_attrs(lines)
    # name 속성의 허용되지 않는 문자 치환
    lines = _sanitize_invalid_name_values(lines)
    # 미닫힌 heredoc 보정
    lines = _repair_unclosed_heredoc(lines)
    # 백틱 포함 라인 주석 처리
    lines = _strip_backtick_lines(lines)
    # ARN 형태 log_group_name 보정
    lines = _fix_log_group_name_arn(lines)
    # data aws_cloudwatch_log_group의 name에 ARN이 들어간 경우 보정
    lines = _fix_data_cloudwatch_log_group_name_arn(lines)
    # metric_transformation 누락 보정
    lines = _ensure_metric_transformation(lines)
    # aws_sns_topic_policy arn 누락 보정
    lines = _ensure_sns_topic_policy_arn(lines)
    # aws_kms_key_policy key_id 누락 보정
    lines = _ensure_kms_key_policy_key_id(lines)
    # aws_cloudwatch_metric_alarm evaluation_periods 누락 보정
    lines = _ensure_cloudwatch_alarm_required_attrs(lines)
    # WAFv2 visibility_config 누락 보정
    lines = _ensure_visibility_config(lines)
    # 외부 IAM 역할/사용자에 대한 위험한 attachment 제거
    lines = _remove_dangerous_iam_attachments(lines)
    # data 블록 내부의 lifecycle 블록 제거
    lines = _strip_lifecycle_from_data_blocks(lines)
    # aws_instance launch_template에 id/name 누락 보정
    lines = _ensure_launch_template_id_or_name(lines)
    # aws_network_acl에 vpc_id 누락 보정
    lines = _ensure_network_acl_vpc_id(lines)
    # resource 블록 내부에 중첩된 resource 블록 추출
    lines = _lift_resources_from_resource_blocks(lines)
    # S3 lifecycle rule에 id 누락 보정
    lines = _ensure_lifecycle_rule_id(lines)
    # S3 lifecycle noncurrent_version_expiration noncurrent_days 누락 보정
    lines = _ensure_noncurrent_days_in_lifecycle(lines)
    # 하드코딩된 AWS 계정 ID → data source 참조로 치환
    lines = _replace_hardcoded_account_id(lines)
    # 하드코딩된 리전 → data source 참조로 치환
    lines = _replace_hardcoded_region_in_arns(lines)
    # placeholder VPC/subnet/SG ID → variable 참조로 치환
    lines = _replace_placeholder_ids(lines)
    # placeholder 이메일/키페어 → variable 참조로 치환
    lines = _replace_placeholder_values(lines)
    # S3 apply 오류 방지: 기존 버킷 resource → data 변환
    lines = _convert_s3_bucket_resource_to_data(lines)
    # S3 apply 오류 방지: BucketOwnerEnforced와 충돌하는 ACL 제거
    lines = _remove_s3_bucket_acl_resources(lines)
    # S3 apply 오류 방지: MFA delete는 Terraform으로 설정 불가
    lines = _fix_mfa_delete(lines)
    # CloudTrail용 S3 bucket policy 누락 보정
    lines = _ensure_cloudtrail_s3_bucket_policy(lines)
    # data source에서 지원하지 않는 속성 참조 치환
    lines = _fix_unsupported_data_attrs(lines)
    # time() 함수 포함 할당 보정
    lines = _fix_time_function_assignments(lines)
    # 리소스별 필수 속성 누락 보정
    lines = _ensure_required_resource_attrs(lines)
    # data.aws_vpc.default 참조 보정
    lines = _ensure_default_vpc_data(lines)
    # aws_flow_log 대상 누락 보정
    lines = _ensure_flow_log_target(lines)
    # 선언 없이 참조된 variable 자동 선언
    lines = _auto_declare_variables(lines)
    # 미닫힌 따옴표 보정
    lines = _repair_unbalanced_quotes(lines)
    # 괄호/대괄호 균형 보정
    lines = _balance_parens_brackets(lines)
    # 중괄호 균형 보정
    lines = _balance_braces(lines)

    # 앞/뒤 공백 라인 제거
    while lines and lines[0].strip() == "":
        lines.pop(0)
    while lines and lines[-1].strip() == "":
        lines.pop()
    return "\n".join(lines).strip()


def apply_error_fixes(tf_code, error_msg, row=None):
    extra_attrs = set()
    for pat in [
        r'Can\'t configure a value for "([^"]+)"',
        r'Value for unconfigurable attribute.*?"([^"]+)"',
    ]:
        for m in re.findall(pat, error_msg, flags=re.DOTALL):
            extra_attrs.add(m)
    if extra_attrs:
        return sanitize_tf_code(tf_code, extra_unconfig_attrs=extra_attrs)
    if "invalid value for name" in error_msg.lower():
        fixed_lines = _sanitize_invalid_name_values(tf_code.splitlines())
        return sanitize_tf_code("\n".join(fixed_lines))
    # Unsupported argument 오류일 경우 해당 인자 제거
    m = re.search(r"Error: Unsupported argument.*?\n.*?:\s+([A-Za-z0-9_]+)\s*=", error_msg, flags=re.DOTALL)
    if m:
        bad_attr = m.group(1)
        lines = tf_code.splitlines()
        filtered = []
        for line in lines:
            if re.match(rf'^\s*{re.escape(bad_attr)}\s*=', line):
                continue
            filtered.append(line)
        return sanitize_tf_code("\n".join(filtered))
    # Unsupported attribute 오류 (data source 속성 미지원) → sanitize 재적용
    if "Unsupported attribute" in error_msg:
        return sanitize_tf_code(tf_code)
    # 선언되지 않은 변수 참조 → _auto_declare_variables가 처리
    if "Reference to undeclared input variable" in error_msg:
        return sanitize_tf_code(tf_code)
    # Unexpected resource instance key (count/for_each 미사용 시 인덱스 접근) → 인덱스 제거
    if "Unexpected resource instance key" in error_msg:
        m2 = re.search(r'(\w+\.\w+\.\w+)\[(\d+)\]', error_msg)
        if m2:
            bad_ref = re.escape(m2.group(0))
            good_ref = m2.group(1)
            tf_code = re.sub(bad_ref, good_ref, tf_code)
        return sanitize_tf_code(tf_code)
    # log_group_name에 ARN이 들어간 경우 보정 시도
    if "log_group_name" in error_msg and "arn:aws:logs" in error_msg:
        return sanitize_tf_code(tf_code)
    if "Insufficient metric_transformation blocks" in error_msg:
        return sanitize_tf_code(tf_code)
    # Invalid resource type → sanitize가 deprecated 타입을 고쳐줌
    if "Invalid resource type" in error_msg or "Invalid data source" in error_msg:
        return sanitize_tf_code(tf_code)
    # Missing required argument → sanitize 재적용 (visibility_config 등)
    if "Missing required argument" in error_msg:
        m_attr = re.search(r'The argument "([^"]+)" is required', error_msg)
        m_res = re.search(r'in resource "([^"]+)"', error_msg)
        if m_attr and m_res:
            attr = m_attr.group(1)
            rtype = m_res.group(1)
            value_expr = _infer_attr_value(attr, row, rtype)
            if value_expr:
                tf_code = _inject_required_attr(tf_code, rtype, attr, value_expr)
                return sanitize_tf_code(tf_code)
        return sanitize_tf_code(tf_code)
    # Insufficient blocks (visibility_config 등) → sanitize 재적용
    if "Insufficient" in error_msg and "blocks" in error_msg:
        return sanitize_tf_code(tf_code)
    # Invalid index (set 인덱싱 등) → sanitize 재적용
    if "Invalid index" in error_msg:
        return sanitize_tf_code(tf_code)
    if any(
        key in error_msg
        for key in ["Unsupported block type", "Invalid block definition", "Invalid character"]
    ):
        return sanitize_tf_code(tf_code)
    if "Unclosed config" in error_msg:
        return sanitize_tf_code(tf_code)
    return tf_code


def validate_with_autofix(tf_code, max_auto_fixes=2, row=None):
    last_err = ""
    for _ in range(max_auto_fixes + 1):
        ok, err = validate_terraform(tf_code)
        if ok:
            return True, tf_code, ""
        last_err = err
        fixed = apply_error_fixes(tf_code, err, row=row)
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

    핵심:
    - main.tf 하나로 '조립'하지 않는다 (중첩 블록 사고 방지)
    - 공통 data/provier/terraform 블록은 고정 파일로 분리
    - tf_code는 단일 파일(candidate.tf)로만 넣고 validate
    """
    import tempfile, subprocess, shutil

    work = tempfile.mkdtemp(prefix="tf-validate-")
    try:
        # 1) candidate.tf : 생성된 코드(이미 sanitize된 결과)
        with open(os.path.join(work, "candidate.tf"), "w", encoding="utf-8") as f:
            f.write(tf_code.strip() + "\n")

        # 2) 00-data.tf : 공통 data는 '최상위 블록'으로만 제공 (중첩 금지)
        with open(os.path.join(work, "00-data.tf"), "w", encoding="utf-8") as f:
            f.write(
                'data "aws_caller_identity" "current" {}\n'
                'data "aws_region" "current" {}\n'
                'data "aws_partition" "current" {}\n'
            )

        # 3) providers.tf : provider는 한 번만
        with open(os.path.join(work, "providers.tf"), "w", encoding="utf-8") as f:
            f.write(
                'provider "aws" {\n'
                '  region = "ap-northeast-2"\n'
                '}\n'
            )

        # 4) versions.tf : required_providers 고정 (가드레일)
        with open(os.path.join(work, "versions.tf"), "w", encoding="utf-8") as f:
            f.write(
                'terraform {\n'
                '  required_providers {\n'
                '    aws = {\n'
                '      source = "hashicorp/aws"\n'
                '    }\n'
                '  }\n'
                '}\n'
            )

        # 5) init (backend 불필요: -backend=false)
        r1 = subprocess.run(
            ["terraform", "init", "-backend=false", "-input=false", "-no-color"],
            cwd=work, capture_output=True, text=True, timeout=120
        )
        if r1.returncode != 0:
            return False, f"init failed: {r1.stdout}\n{r1.stderr}"

        # 6) validate
        r2 = subprocess.run(
            ["terraform", "validate", "-no-color"],
            cwd=work, capture_output=True, text=True, timeout=60
        )
        if r2.returncode != 0:
            return False, (r2.stdout + "\n" + r2.stderr).strip()
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
    iam_guard = ""
    if not ALLOW_IAM_CREATE:
        iam_guard = (
            "\nIAM Guardrails:\n"
            "- Do NOT create IAM policies, roles, or instance profiles\n"
            "- Use data sources to reference existing IAM resources\n"
        )
    return f"""Generate Terraform code to fix this AWS security finding.

Check ID: {row.get('check_id', '')}
Title: {row.get('check_title', '')}
Severity: {row.get('severity', '')}
Resource UID: {row.get('resource_uid', '')}
Resource ARN: {row.get('resource_arn', '')}
Resource Name: {row.get('resource_name', '')}
Resource Type: {row.get('resource_type', '')}
Account ID: {row.get('account_id', '')}
Region: {row.get('region', 'ap-northeast-2')}
Recommendation: {row.get('recommendation_text', '')}

Requirements:
- Output ONLY valid Terraform HCL code, nothing else
- No markdown, no explanations, no code fences, no text before or after the code
- Prefer modifying existing resources referenced by the finding; create new resources only when required
- NEVER use "import" blocks
- NEVER set computed/read-only attributes (arn, id, key_id, owner_id, creation_date, unique_id) in resource blocks
- Avoid hardcoded ARNs/IDs in resource blocks; use data sources to look up existing resources when needed
- Do NOT define data "aws_caller_identity" "current", data "aws_region" "current", or data "aws_partition" "current" — these are pre-provided by the framework. Just reference them directly (e.g., data.aws_caller_identity.current.account_id)
- Include a single provider "aws" block for ap-northeast-2 region WITHOUT alias
- NEVER use provider aliases (no "alias" in provider, no "provider = aws.xxx" in resources)
- For IAM policies, use jsonencode() instead of heredoc (<<EOF) to avoid string termination issues
- Add HCL comments (lines starting with #) explaining what the code does
- Make sure all required attributes are set for each resource type
- Use unique resource names with a "remediation_" prefix to avoid conflicts
- For aws_s3_bucket: do NOT use deprecated "acl" argument or inline "server_side_encryption_configuration" block. Use separate resources: aws_s3_bucket_acl, aws_s3_bucket_server_side_encryption_configuration
- For EC2 instances needing IAM roles: create an aws_iam_instance_profile resource and reference it. Do NOT assign a role name directly to iam_instance_profile
- For IAM user policy attachments: the "user" argument must be an IAM user name (string), NOT an ARN. Do NOT use data.aws_caller_identity.current.arn as a user name
- For aws_iam_role_policy_attachment: use correct managed policy ARNs (e.g., "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"), NOT deprecated policy names
- For aws_sns_topic_policy: the "arn" argument is REQUIRED — set it to the SNS topic ARN (e.g., aws_sns_topic.xxx.arn)
- For aws_kms_key_policy: the "key_id" argument is REQUIRED — set it to the KMS key ID (e.g., aws_kms_key.xxx.id)
- For aws_backup_selection: the "iam_role_arn" argument is REQUIRED — create an IAM role for AWS Backup and reference its ARN
- For aws_wafv2_web_acl: the "visibility_config" block is REQUIRED inside both the web ACL and each rule
- For aws_backup_vault: do NOT use "lifecycle_rule" block (it doesn't exist). Lifecycle rules go in aws_backup_plan
- Do NOT use the deprecated "aws_subnet_ids" data source — use "aws_subnets" instead
- Do NOT use "aws_instance_profile_attachment" or "aws_ec2_instance_profile" resource types — they don't exist. Use "aws_iam_instance_profile" instead
- For aws_instance: either "ami" or "launch_template" must be specified
- For launch_template blocks inside aws_instance: either "id" or "name" must be specified
- Do NOT index set-type attributes directly (e.g., vpc_security_group_ids[0]). Use tolist() first: tolist(data.xxx.vpc_security_group_ids)[0]
{iam_guard}

Output the Terraform code:"""


# 출력 디렉터리 보장
os.makedirs(args.output_dir, exist_ok=True)

# P0/P1/P2 우선순위만 자동 리메디에이션 대상 (P3는 수동)
high_priority = df[df['priority'].isin(['P0', 'P1', 'P2'])]
# check_id가 비어있는 행은 제외
high_priority = high_priority[
    high_priority['check_id'].notna()
    & ~high_priority['check_id'].astype(str).str.strip().str.lower().isin(["", "nan", "none"])
]
print(f"Found {len(high_priority)} high-priority findings (P0/P1/P2) out of {len(df)} total")

# check_id 기준 중복 제거 (같은 체크가 여러 리소스에 반복될 수 있음)
unique_checks = high_priority.drop_duplicates(subset=['check_id'], keep='first')
skipped_checks = [c for c in unique_checks['check_id'] if c in SKIP_CHECKS]
unique_checks = unique_checks[~unique_checks['check_id'].isin(SKIP_CHECKS)]
print(f"Unique check_ids: {len(unique_checks)} (skipped {len(skipped_checks)} non-terraform checks: {skipped_checks})")

# 생성 결과/통계
generated = []
bedrock_failures = 0
_consolidated_files_written = set()   # CONSOLIDATE_CHECKS용: 이미 기록한 파일 추적

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
        ok, tf_code, err = validate_with_autofix(tf_code, row=row)

        # Bedrock 코드가 실패하면 IaC 스니펫으로 재시도
        if not ok and source == "bedrock":
            fallback = fallback_from_iac_snippet(str(row.get('check_id', '')), category)  # 체크 ID/카테고리 스니펫 조회
            if fallback:
                fb_code = sanitize_tf_code(fallback)
                ok, fb_code, err = validate_with_autofix(fb_code, row=row)
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
                ok, tf_code, err = validate_with_autofix(tf_code, row=row)
                if ok:
                    print(f"  validate OK (attempt {attempt})")
                    break

        if not ok:
            if ALLOW_SKIP:
                print(f"SKIP {check_id}: failed validation after {MAX_RETRIES} attempts")
                continue
            tf_code = _fallback_stub(row, err)
            ok, tf_code, _ = validate_with_autofix(tf_code, row=row)
            source = "fallback_stub"

        # resource/data 블록이 하나도 없으면 skip (주석만 남은 경우)
        if not re.search(r'^\s*(resource|data)\s+"', tf_code, re.MULTILINE):
            if ALLOW_SKIP:
                print(f"SKIP (no resource/data blocks after sanitize): {check_id}")
                continue
            tf_code = _fallback_stub(row, "no resource/data blocks")
            ok, tf_code, _ = validate_with_autofix(tf_code, row=row)
            source = "fallback_stub"

        # singleton 통합 대상이면 하나의 파일로 병합
        raw_check_id = str(row.get('check_id', ''))
        consolidated_file = CONSOLIDATE_CHECKS.get(raw_check_id)
        if consolidated_file:
            filename = consolidated_file
            if filename in _consolidated_files_written:
                # 이미 기록됨 → manifest에만 추가
                generated.append({
                    'check_id': row.get('check_id'),
                    'check_title': row.get('check_title'),
                    'file': filename,
                    'priority': row.get('priority'),
                    'category': category,
                    'source': source
                })
                print(f"Consolidated (already written): {check_id} -> {filename}")
                continue
            _consolidated_files_written.add(filename)
        else:
            filename = f"fix-{check_id}.tf"

        # .tf 파일로 저장
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


