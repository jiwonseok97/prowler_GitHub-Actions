# =============================================================================
# generate_remediation.py - Terraform ?닿껐 肄붾뱶 AI ?앹꽦 ?ㅽ겕由쏀듃
# =============================================================================
# ??븷: 怨좎슦?좎닚??P0/P1/P2) finding?????Claude Haiku媛 Terraform ?닿껐 肄붾뱶 ?앹꽦
# ?낅젰: mcp/output/findings-scored-ai.csv
# 異쒕젰: remediation/fix-{check_id}.tf (媛쒕퀎 Terraform ?뚯씪)
#       remediation/manifest.json (?앹꽦???뚯씪 紐⑸줉)
#
# 肄붾뱶 ?앹꽦 ?꾨왂:
#   1李? AWS Bedrock Claude Haiku??finding ?뺣낫瑜??꾨떖?섏뿬 Terraform 肄붾뱶 ?앹꽦
#   2李? Bedrock ?ㅽ뙣 ??check_to_iac.yaml 留ㅽ븨??IaC ?ㅻ땲?レ쑝濡??대갚
#
# ?앹꽦??.tf ?뚯씪? ?뚰겕?뚮줈?곗뿉???먮룞?쇰줈 PR ?앹꽦???ъ슜??
# =============================================================================

import argparse
import json
import os
import pandas as pd

try:
    import boto3
except Exception:
    boto3 = None  # boto3 誘몄꽕移????대갚?쇰줈 ?숈옉

try:
    import yaml
except Exception:
    yaml = None  # pyyaml 誘몄꽕移???IaC ?대갚 鍮꾪솢?깊솕

parser = argparse.ArgumentParser()
parser.add_argument("--input", required=True)
parser.add_argument("--output-dir", required=True)
parser.add_argument("--iac-mapping", default="iac/mappings/check_to_iac.yaml")
args = parser.parse_args()

df = pd.read_csv(args.input)

# --- Bedrock ?ㅼ젙 (?섍꼍蹂?섎줈 ?ㅻ쾭?쇱씠??媛?? ---
MODEL_ID = os.getenv("BEDROCK_MODEL_ID", "anthropic.claude-3-haiku-20240307-v1:0")
BEDROCK_REGION = os.getenv("BEDROCK_REGION", "ap-northeast-2")
MAX_TOKENS = int(os.getenv("BEDROCK_MAX_TOKENS", "1024"))  # Terraform 肄붾뱶??湲몄뼱??1024
USE_BEDROCK = os.getenv("USE_BEDROCK", "true").lower() == "true"

# --- IaC ?ㅻ땲??留ㅽ븨 濡쒕뱶 (Bedrock ?ㅽ뙣 ???대갚?? ---
iac_map = {}
if yaml and os.path.exists(args.iac_mapping):
    with open(args.iac_mapping) as f:
        iac_map = yaml.safe_load(f) or {}
    print(f"Loaded {len(iac_map)} IaC snippet mappings")

def categorize_check_id(check_id: str) -> str:
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
    """AWS Bedrock Claude 3 Haiku API ?몄텧?섏뿬 Terraform 肄붾뱶 ?앹꽦"""
    if not USE_BEDROCK or boto3 is None:
        print("Bedrock disabled or boto3 unavailable")
        return None
    try:
        client = boto3.client("bedrock-runtime", region_name=BEDROCK_REGION)
        body = {
            "anthropic_version": "bedrock-2023-05-31",
            "max_tokens": MAX_TOKENS,
            "temperature": 0.1,  # ??? temperature濡??쇨???肄붾뱶 ?앹꽦
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


def fallback_from_iac_snippet(check_id):
    """Bedrock ?ㅽ뙣 ??check_to_iac.yaml 留ㅽ븨?먯꽌 誘몃━ ?묒꽦??Terraform ?ㅻ땲??濡쒕뱶"""
    snippet_path = iac_map.get(check_id)
    if not snippet_path:
        return None
    if not snippet_path.endswith(".tf"):
        return None  # .tf ?뚯씪留??ъ슜 (.md ???쒖쇅)
    if os.path.exists(snippet_path):
        with open(snippet_path) as f:
            return f.read().strip()
    return None


def make_remediation_prompt(row):
    """finding ?곗씠?곕? 湲곕컲?쇰줈 Terraform 肄붾뱶 ?앹꽦 ?꾨＼?꾪듃 援ъ꽦"""
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
- NEVER set computed/read-only attributes (arn, id, key_id, owner_id, creation_date, unique_id) in resource blocks
- Use "data" sources to reference existing resources, NOT resource blocks with hardcoded ARNs
- Use "import" blocks if you need to bring existing resources under Terraform management
- Include a single provider "aws" block for ap-northeast-2 region WITHOUT alias
- NEVER use provider aliases (no "alias" in provider, no "provider = aws.xxx" in resources)
- Add HCL comments (lines starting with #) explaining what the code does

Output the Terraform code:"""


os.makedirs(args.output_dir, exist_ok=True)

# P0/P1/P2 ?곗꽑?쒖쐞留??먮룞 Remediation ???(P3? ?섎룞 ???
high_priority = df[df['priority'].isin(['P0', 'P1', 'P2'])]
print(f"Found {len(high_priority)} high-priority findings (P0/P1/P2) out of {len(df)} total")

generated = []
bedrock_failures = 0

for _, row in high_priority.iterrows():
    # check_id?먯꽌 ?뚯씪紐낆뿉 ?ъ슜?????녿뒗 臾몄옄 移섑솚
    check_id = str(row.get('check_id', 'unknown')).replace('/', '-').replace(':', '-')
    category = categorize_check_id(row.get('check_id', ''))

    # 1李? Bedrock AI濡?Terraform 肄붾뱶 ?앹꽦 ?쒕룄
    tf_code = call_bedrock(make_remediation_prompt(row))

    # 2李? Bedrock ?ㅽ뙣 ??IaC ?ㅻ땲??留ㅽ븨?먯꽌 ?대갚
    if not tf_code:
        bedrock_failures += 1
        tf_code = fallback_from_iac_snippet(str(row.get('check_id', '')))
        if tf_code:
            print(f"Fallback IaC snippet used for: {check_id}")

    if tf_code:
        # AI ?묐떟??留덊겕?ㅼ슫 肄붾뱶 ?쒖뒪媛 ?ы븿??寃쎌슦 ?쒓굅
        tf_code = tf_code.replace('```hcl', '').replace('```terraform', '').replace('```', '').strip()

        # Strip trailing non-HCL text (AI sometimes appends plain-text explanations)
        import re
        _hcl_line_re = re.compile(
            r'^(\s*$|#|//|resource\s|data\s|provider\s|variable\s|locals\s'
            r'|terraform\s|output\s|module\s|import\s|\s+\w+|\})'
        )
        _cleaned = []
        for _line in tf_code.split('\n'):
            if _hcl_line_re.match(_line):
                _cleaned.append(_line)
            else:
                break
        tf_code = '\n'.join(_cleaned).strip()

        if not tf_code:
            print(f"SKIP (generated code was empty after cleanup): {check_id}")
            continue

        # 媛쒕퀎 .tf ?뚯씪濡????
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
            'source': 'bedrock' if bedrock_failures == 0 or tf_code != fallback_from_iac_snippet(str(row.get('check_id', ''))) else 'iac_snippet'
        })
        print(f"Generated: {filename}")
    else:
        print(f"SKIP (no Bedrock response and no IaC snippet): {check_id}")

# ?앹꽦???뚯씪 紐⑸줉??manifest.json?쇰줈 ???
with open(os.path.join(args.output_dir, 'manifest.json'), 'w') as f:
    json.dump(generated, f, indent=2)

print(f"Total generated: {len(generated)} remediation files")
if bedrock_failures > 0:
    print(f"WARNING: Bedrock failed for {bedrock_failures}/{len(high_priority)} findings")


