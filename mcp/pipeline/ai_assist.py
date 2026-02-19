# =============================================================================
# ai_assist.py - Claude Haiku AI 요약 및 우선순위 근거 생성 스크립트
# =============================================================================
# 역할:

# AWS Bedrock의 Claude 3 Haiku를 호출하여 각 finding에 대해
# - ai_summary (보고서용 요약)
# - ai_priority_rationale (우선순위 선정 근거)를 생성한다.

# 입력:  mcp/output/findings-scored.csv
# 출력:  mcp/output/findings-scored-ai.csv


# 각 finding마다 2회 Bedrock 호출:

# 1) 요약 생성
# 2) 우선순위 근거 생성

# Bedrock 실패 시 fallback 규칙 기반 응답으로 대체하여
# 파이프라인이 중단되지 않도록 한다.

# =============================================================================

import argparse
import json
import os
import pandas as pd

try:
    import boto3
except Exception:
    boto3 = None  # boto3 미설치 환경에서도 fallback 동작

parser = argparse.ArgumentParser()
parser.add_argument("--input", required=True)
parser.add_argument("--output", required=True)
args = parser.parse_args()

df = pd.read_csv(args.input)

# --- Bedrock 설정 (환경 변수로 오버라이드 가능) ---

DEFAULT_BEDROCK_REGION = "ap-northeast-2"
DEFAULT_MODEL_ID = "anthropic.claude-3-haiku-20240307-v1:0"

MODEL_ID = os.getenv("BEDROCK_MODEL_ID", DEFAULT_MODEL_ID)
BEDROCK_REGION = os.getenv("BEDROCK_REGION", DEFAULT_BEDROCK_REGION)

# 서울 리전 강제 (오사카 호출 방지)

if BEDROCK_REGION != DEFAULT_BEDROCK_REGION:
print(f"[Bedrock] Override region {BEDROCK_REGION} -> {DEFAULT_BEDROCK_REGION}")
BEDROCK_REGION = DEFAULT_BEDROCK_REGION

# short name → ARN 변환

if not MODEL_ID.startswith("arn:aws:bedrock:"):
MODEL_ID = f"arn:aws:bedrock:{BEDROCK_REGION}::foundation-model/{MODEL_ID}"

MAX_TOKENS = int(os.getenv("BEDROCK_MAX_TOKENS", "256"))
TEMPERATURE = float(os.getenv("BEDROCK_TEMPERATURE", "0.2"))
USE_BEDROCK = os.getenv("USE_BEDROCK", "true").lower() == "true"

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


# --- 각 finding에 대해 AI 결과 생성 ---

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
