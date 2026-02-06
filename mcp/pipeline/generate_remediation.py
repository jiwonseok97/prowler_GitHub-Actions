import argparse
import json
import os
import pandas as pd

try:
    import boto3
except Exception:
    boto3 = None

try:
    import yaml
except Exception:
    yaml = None

parser = argparse.ArgumentParser()
parser.add_argument("--input", required=True)
parser.add_argument("--output-dir", required=True)
parser.add_argument("--iac-mapping", default="repo/iac/mappings/check_to_iac.yaml")
args = parser.parse_args()

df = pd.read_csv(args.input)

MODEL_ID = os.getenv("BEDROCK_MODEL_ID", "anthropic.claude-3-haiku-20240307-v1:0")
BEDROCK_REGION = os.getenv("BEDROCK_REGION", "ap-northeast-2")
MAX_TOKENS = int(os.getenv("BEDROCK_MAX_TOKENS", "1024"))
USE_BEDROCK = os.getenv("USE_BEDROCK", "true").lower() == "true"

# Load IaC snippet mapping for fallback
iac_map = {}
if yaml and os.path.exists(args.iac_mapping):
    with open(args.iac_mapping) as f:
        iac_map = yaml.safe_load(f) or {}
    print(f"Loaded {len(iac_map)} IaC snippet mappings")


def call_bedrock(prompt):
    if not USE_BEDROCK or boto3 is None:
        print("Bedrock disabled or boto3 unavailable")
        return None
    try:
        client = boto3.client("bedrock-runtime", region_name=BEDROCK_REGION)
        body = {
            "anthropic_version": "bedrock-2023-05-31",
            "max_tokens": MAX_TOKENS,
            "temperature": 0.1,
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
    """IaC snippet mapping에서 Terraform 코드를 가져오는 폴백"""
    snippet_path = iac_map.get(check_id)
    if not snippet_path:
        return None
    if not snippet_path.endswith(".tf"):
        return None
    if os.path.exists(snippet_path):
        with open(snippet_path) as f:
            return f.read().strip()
    # repo/ prefix도 시도
    alt = os.path.join("repo", snippet_path) if not snippet_path.startswith("repo/") else snippet_path
    if os.path.exists(alt):
        with open(alt) as f:
            return f.read().strip()
    return None


def make_remediation_prompt(row):
    return f"""Generate Terraform code to fix this AWS security finding.

Check ID: {row.get('check_id', '')}
Title: {row.get('check_title', '')}
Severity: {row.get('severity', '')}
Resource UID: {row.get('resource_uid', '')}
Region: {row.get('region', 'ap-northeast-2')}
Recommendation: {row.get('recommendation_text', '')}

Requirements:
- Output ONLY valid Terraform HCL code
- No markdown, no explanations, no code fences
- Use data sources to reference existing resources when possible
- Include provider configuration for ap-northeast-2 region
- Add comments explaining what the code does

Output the Terraform code:"""


os.makedirs(args.output_dir, exist_ok=True)

# P0, P1, P2 priority only for auto remediation
high_priority = df[df['priority'].isin(['P0', 'P1', 'P2'])]
print(f"Found {len(high_priority)} high-priority findings (P0/P1/P2) out of {len(df)} total")

generated = []
bedrock_failures = 0

for _, row in high_priority.iterrows():
    check_id = str(row.get('check_id', 'unknown')).replace('/', '-').replace(':', '-')

    # 1차: Bedrock AI 생성 시도
    tf_code = call_bedrock(make_remediation_prompt(row))

    # 2차: Bedrock 실패 시 IaC snippet 폴백
    if not tf_code:
        bedrock_failures += 1
        tf_code = fallback_from_iac_snippet(str(row.get('check_id', '')))
        if tf_code:
            print(f"Fallback IaC snippet used for: {check_id}")

    if tf_code:
        # Remove markdown code fences if present
        tf_code = tf_code.replace('```hcl', '').replace('```terraform', '').replace('```', '').strip()

        filename = f"fix-{check_id}.tf"
        filepath = os.path.join(args.output_dir, filename)
        with open(filepath, 'w') as f:
            f.write(tf_code)
        generated.append({
            'check_id': row.get('check_id'),
            'check_title': row.get('check_title'),
            'file': filename,
            'priority': row.get('priority'),
            'source': 'bedrock' if bedrock_failures == 0 or tf_code != fallback_from_iac_snippet(str(row.get('check_id', ''))) else 'iac_snippet'
        })
        print(f"Generated: {filename}")
    else:
        print(f"SKIP (no Bedrock response and no IaC snippet): {check_id}")

# Save manifest
with open(os.path.join(args.output_dir, 'manifest.json'), 'w') as f:
    json.dump(generated, f, indent=2)

print(f"Total generated: {len(generated)} remediation files")
if bedrock_failures > 0:
    print(f"WARNING: Bedrock failed for {bedrock_failures}/{len(high_priority)} findings")
