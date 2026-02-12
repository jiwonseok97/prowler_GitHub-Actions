# =============================================================================
# ai_assist.py - Claude Haiku AI ?붿빟 諛??곗꽑?쒖쐞 洹쇨굅 ?앹꽦 ?ㅽ겕由쏀듃
# =============================================================================
# ??븷: AWS Bedrock??Claude 3 Haiku瑜??몄텧?섏뿬 媛?finding?????
#       AI 湲곕컲 ?붿빟怨??곗꽑?쒖쐞 諛곗젙 洹쇨굅瑜??앹꽦
# ?낅젰: mcp/output/findings-scored.csv
# 異쒕젰: mcp/output/findings-scored-ai.csv (ai_summary, ai_priority_rationale 異붽?)
#
# 媛?finding留덈떎 2??Bedrock ?몄텧:
#   1) ai_summary: 蹂닿퀬?쒖슜 1~2臾몄옣 ?붿빟
#   2) ai_priority_rationale: ?곗꽑?쒖쐞 諛곗젙 洹쇨굅 ?ㅻ챸
#
# Bedrock ?ㅽ뙣 ??猷?湲곕컲 ?대갚?쇰줈 ?泥?(?뚯씠?꾨씪??以묐떒 諛⑹?)
# =============================================================================

import argparse
import json
import os
import pandas as pd

try:
    import boto3
except Exception:
    boto3 = None  # boto3 誘몄꽕移????대갚?쇰줈 ?숈옉

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
# Force Seoul region to avoid accidental Osaka calls
if BEDROCK_REGION != DEFAULT_BEDROCK_REGION:
    print(f"[Bedrock] Override region {BEDROCK_REGION} -> {DEFAULT_BEDROCK_REGION}")
    BEDROCK_REGION = DEFAULT_BEDROCK_REGION
# Normalize to ARN if model id is a short name
if not MODEL_ID.startswith("arn:aws:bedrock:"):
    MODEL_ID = f"arn:aws:bedrock:{BEDROCK_REGION}::foundation-model/{MODEL_ID}"
MAX_TOKENS = int(os.getenv("BEDROCK_MAX_TOKENS", "256"))        # ?묐떟 理쒕? ?좏겙 ??
TEMPERATURE = float(os.getenv("BEDROCK_TEMPERATURE", "0.2"))    # ??쓣?섎줉 ?쇨????묐떟
USE_BEDROCK = os.getenv("USE_BEDROCK", "true").lower() == "true"  # Bedrock ?ъ슜 ?щ?


def fallback_summary(row):
    """Bedrock ?ㅽ뙣 ??猷?湲곕컲 ?붿빟 ?앹꽦 (?대갚)"""
    title = str(row.get("check_title", "")).strip()
    return f"Finding summary: {title}" if title else "Finding summary: N/A"


def fallback_rationale(row):
    """Bedrock ?ㅽ뙣 ??猷?湲곕컲 ?곗꽑?쒖쐞 洹쇨굅 ?앹꽦 (?대갚)"""
    prio = str(row.get("priority", "P3"))
    sev = str(row.get("severity", "medium"))
    br = str(row.get("blast_radius", "3"))
    return f"Priority {prio} based on severity={sev} and blast_radius={br}."


def call_bedrock(prompt):
    """AWS Bedrock Claude 3 Haiku API ?몄텧"""
    if not USE_BEDROCK or boto3 is None:
        return None
    try:
        client = boto3.client("bedrock-runtime", region_name=BEDROCK_REGION)

        # Claude Messages API ?뺤떇?쇰줈 ?붿껌 援ъ꽦
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
        # Claude ?묐떟 ?뺤떇: {"content": [{"type": "text", "text": "..."}]}
        parts = payload.get("content", [])
        if not parts:
            return None
        return parts[0].get("text", "").strip()
    except Exception as e:
        print(f"Bedrock error: {e}")
        return None


def make_prompt(row, kind):
    """finding ?곗씠?곕? 湲곕컲?쇰줈 Claude ?꾨＼?꾪듃 ?앹꽦"""
    title = str(row.get("check_title", ""))
    severity = str(row.get("severity", ""))
    prio = str(row.get("priority", ""))
    risk = str(row.get("risk_score", ""))
    desc = str(row.get("recommendation_text", ""))
    if kind == "summary":
        # 蹂닿퀬?쒖슜 ?붿빟 ?꾨＼?꾪듃
        return (
            "Summarize this finding in 1-2 sentences for a security report. "
            "Be concise and factual.\n"
            f"Title: {title}\nSeverity: {severity}\nRisk score: {risk}\nDetails: {desc}"
        )
    # ?곗꽑?쒖쐞 洹쇨굅 ?꾨＼?꾪듃
    return (
        "Explain why this priority was assigned in 1 sentence. "
        "Reference severity and blast radius.\n"
        f"Title: {title}\nSeverity: {severity}\nPriority: {prio}\nRisk score: {risk}"
    )


# --- 媛?finding?????AI ?붿빟 + 洹쇨굅 ?앹꽦 ---
summaries = []
rationales = []

for _, row in df.iterrows():
    # Bedrock ?몄텧 ?ㅽ뙣 ??or ?곗궛?먮줈 ?대갚 ?⑥닔 ?먮룞 ?곸슜
    s = call_bedrock(make_prompt(row, "summary")) or fallback_summary(row)
    r = call_bedrock(make_prompt(row, "rationale")) or fallback_rationale(row)
    summaries.append(s)
    rationales.append(r)

# 寃곌낵 而щ읆 異붽?
df["ai_summary"] = summaries                  # AI ?앹꽦 ?붿빟
df["ai_priority_rationale"] = rationales       # AI ?앹꽦 ?곗꽑?쒖쐞 洹쇨굅

df.to_csv(args.output, index=False)


