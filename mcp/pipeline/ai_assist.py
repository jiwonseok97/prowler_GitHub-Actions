import argparse
import json
import os
import pandas as pd

try:
    import boto3
except Exception:
    boto3 = None

parser = argparse.ArgumentParser()
parser.add_argument("--input", required=True)
parser.add_argument("--output", required=True)
args = parser.parse_args()

df = pd.read_csv(args.input)

MODEL_ID = os.getenv("BEDROCK_MODEL_ID", "anthropic.claude-3-haiku-20240307-v1:0")  # 서울 리전 지원
BEDROCK_REGION = os.getenv("BEDROCK_REGION", "ap-northeast-2")  # 서울 리전
MAX_TOKENS = int(os.getenv("BEDROCK_MAX_TOKENS", "256"))
TEMPERATURE = float(os.getenv("BEDROCK_TEMPERATURE", "0.2"))
USE_BEDROCK = os.getenv("USE_BEDROCK", "true").lower() == "true"  # 기본 활성화

def fallback_summary(row):
    title = str(row.get("check_title", "")).strip()
    return f"Finding summary: {title}" if title else "Finding summary: N/A"

def fallback_rationale(row):
    prio = str(row.get("priority", "P3"))
    sev = str(row.get("severity", "medium"))
    br = str(row.get("blast_radius", "3"))
    return f"Priority {prio} based on severity={sev} and blast_radius={br}."

def call_bedrock(prompt):
    if not USE_BEDROCK or boto3 is None:
        return None
    try:
        client = boto3.client("bedrock-runtime", region_name=BEDROCK_REGION)

        # Claude Messages API 형식
        body = {
            "anthropic_version": "bedrock-2023-05-31",
            "max_tokens": MAX_TOKENS,
            "temperature": TEMPERATURE,
            "messages": [{"role": "user", "content": prompt}],
        }
        resp = client.invoke_model(
            modelId=MODEL_ID,
            contentType="application/json",
            accept="application/json",
            body=json.dumps(body),
        )
        payload = json.loads(resp["body"].read())
        # Claude 응답 형식: {"content": [{"type": "text", "text": "..."}]}
        parts = payload.get("content", [])
        if not parts:
            return None
        return parts[0].get("text", "").strip()
    except Exception as e:
        print(f"Bedrock error: {e}")
        return None

def make_prompt(row, kind):
    title = str(row.get("check_title", ""))
    severity = str(row.get("severity", ""))
    prio = str(row.get("priority", ""))
    risk = str(row.get("risk_score", ""))
    desc = str(row.get("recommendation_text", ""))
    if kind == "summary":
        return (
            "Summarize this finding in 1-2 sentences for a security report. "
            "Be concise and factual.\n"
            f"Title: {title}\nSeverity: {severity}\nRisk score: {risk}\nDetails: {desc}"
        )
    return (
        "Explain why this priority was assigned in 1 sentence. "
        "Reference severity and blast radius.\n"
        f"Title: {title}\nSeverity: {severity}\nPriority: {prio}\nRisk score: {risk}"
    )

summaries = []
rationales = []

for _, row in df.iterrows():
    s = call_bedrock(make_prompt(row, "summary")) or fallback_summary(row)
    r = call_bedrock(make_prompt(row, "rationale")) or fallback_rationale(row)
    summaries.append(s)
    rationales.append(r)

df["ai_summary"] = summaries
df["ai_priority_rationale"] = rationales

df.to_csv(args.output, index=False)
