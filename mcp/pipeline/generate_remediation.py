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


def sanitize_tf_code(code, extra_unconfig_attrs=None):
    if not code:
        return ""
    code = _strip_code_fences(code)
    lines = code.splitlines()
    lines = _comment_explanations(lines)
    lines = _remove_import_blocks(lines)
    lines = _convert_data_only_resources(lines)
    lines = _remove_provider_blocks(lines)
    lines = _strip_unconfigurable_attrs_in_resources(lines, extra_unconfig_attrs)

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


def fallback_from_iac_snippet(check_id):
    """Bedrock 실패 시 check_to_iac.yaml 매핑에서 스니펫을 로드."""
    snippet_path = iac_map.get(check_id)
    if not snippet_path:
        return None
    if not snippet_path.endswith(".tf"):
        return None  # .tf만 사용 (.md 등은 제외)
    if os.path.exists(snippet_path):
        with open(snippet_path) as f:
            return f.read().strip()
    return None


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

    # 1차: Bedrock으로 Terraform 코드 생성 시도
    original_prompt = make_remediation_prompt(row)
    tf_code = call_bedrock(original_prompt)
    source = "bedrock"

    # 2차: Bedrock 실패 시 IaC 스니펫으로 대체
    if not tf_code:
        bedrock_failures += 1
        tf_code = fallback_from_iac_snippet(str(row.get('check_id', '')))
        source = "iac_snippet"
        if tf_code:
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
            fallback = fallback_from_iac_snippet(str(row.get('check_id', '')))
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
