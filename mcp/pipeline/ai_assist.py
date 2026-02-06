# =============================================================================
# ai_assist.py - Claude Haiku AI 요약 및 우선순위 근거 생성 스크립트
# =============================================================================
# 역할: AWS Bedrock의 Claude 3 Haiku를 호출하여 각 finding에 대해
#       AI 기반 요약과 우선순위 배정 근거를 생성
# 입력: mcp/output/findings-scored.csv
# 출력: mcp/output/findings-scored-ai.csv (ai_summary, ai_priority_rationale 추가)
#
# 각 finding마다 2회 Bedrock 호출:
#   1) ai_summary: 보고서용 1~2문장 요약
#   2) ai_priority_rationale: 우선순위 배정 근거 설명
#
# Bedrock 실패 시 룰 기반 폴백으로 대체 (파이프라인 중단 방지)
# =============================================================================

import argparse
import json
import os
import pandas as pd

try:
    import boto3
except Exception:
    boto3 = None  # boto3 미설치 시 폴백으로 동작

parser = argparse.ArgumentParser()
parser.add_argument("--input", required=True)
parser.add_argument("--output", required=True)
args = parser.parse_args()

df = pd.read_csv(args.input)

# --- Bedrock 설정 (환경변수로 오버라이드 가능) ---
MODEL_ID = os.getenv("BEDROCK_MODEL_ID", "anthropic.claude-3-haiku-20240307-v1:0")  # 서울 리전 지원 모델
BEDROCK_REGION = os.getenv("BEDROCK_REGION", "ap-northeast-2")  # 서울 리전
MAX_TOKENS = int(os.getenv("BEDROCK_MAX_TOKENS", "256"))        # 응답 최대 토큰 수
TEMPERATURE = float(os.getenv("BEDROCK_TEMPERATURE", "0.2"))    # 낮을수록 일관된 응답
USE_BEDROCK = os.getenv("USE_BEDROCK", "true").lower() == "true"  # Bedrock 사용 여부


def fallback_summary(row):
    """Bedrock 실패 시 룰 기반 요약 생성 (폴백)"""
    title = str(row.get("check_title", "")).strip()
    return f"Finding summary: {title}" if title else "Finding summary: N/A"


def fallback_rationale(row):
    """Bedrock 실패 시 룰 기반 우선순위 근거 생성 (폴백)"""
    prio = str(row.get("priority", "P3"))
    sev = str(row.get("severity", "medium"))
    br = str(row.get("blast_radius", "3"))
    return f"Priority {prio} based on severity={sev} and blast_radius={br}."


def call_bedrock(prompt):
    """AWS Bedrock Claude 3 Haiku API 호출"""
    if not USE_BEDROCK or boto3 is None:
        return None
    try:
        client = boto3.client("bedrock-runtime", region_name=BEDROCK_REGION)

        # Claude Messages API 형식으로 요청 구성
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
    """finding 데이터를 기반으로 Claude 프롬프트 생성"""
    title = str(row.get("check_title", ""))
    severity = str(row.get("severity", ""))
    prio = str(row.get("priority", ""))
    risk = str(row.get("risk_score", ""))
    desc = str(row.get("recommendation_text", ""))
    if kind == "summary":
        # 보고서용 요약 프롬프트
        return (
            "Summarize this finding in 1-2 sentences for a security report. "
            "Be concise and factual.\n"
            f"Title: {title}\nSeverity: {severity}\nRisk score: {risk}\nDetails: {desc}"
        )
    # 우선순위 근거 프롬프트
    return (
        "Explain why this priority was assigned in 1 sentence. "
        "Reference severity and blast radius.\n"
        f"Title: {title}\nSeverity: {severity}\nPriority: {prio}\nRisk score: {risk}"
    )


# --- 각 finding에 대해 AI 요약 + 근거 생성 ---
summaries = []
rationales = []

for _, row in df.iterrows():
    # Bedrock 호출 실패 시 or 연산자로 폴백 함수 자동 적용
    s = call_bedrock(make_prompt(row, "summary")) or fallback_summary(row)
    r = call_bedrock(make_prompt(row, "rationale")) or fallback_rationale(row)
    summaries.append(s)
    rationales.append(r)

# 결과 컬럼 추가
df["ai_summary"] = summaries                  # AI 생성 요약
df["ai_priority_rationale"] = rationales       # AI 생성 우선순위 근거

df.to_csv(args.output, index=False)
