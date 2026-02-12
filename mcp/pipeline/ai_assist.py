# -*- coding: utf-8 -*-
# =============================================================================
# ai_assist.py - Claude Haiku 기반 AI 요약 및 우선순위 근거 생성 스크립트
# =============================================================================
# 목적:
#   - AWS Bedrock의 Claude 3 Haiku를 호출하여 각 finding에 대해
#     1) ai_summary            : 보고서용 1~2문장 요약
#     2) ai_priority_rationale : 우선순위(P0~) 산정 근거 1문장 설명
#
# 입력:
#   - mcp/output/findings-scored.csv
#
# 출력:
#   - mcp/output/findings-scored-ai.csv
#     (ai_summary, ai_priority_rationale 컬럼 추가)
#
# 호출 방식:
#   - finding 1개당 Bedrock 2회 호출(요약/근거)
#
# 장애/비용/운영 고려:
#   - Bedrock 호출 실패 시 fallback 문구로 대체(파이프라인 중단 방지)
#   - Region은 기본 ap-northeast-2(서울) 고정(실수로 다른 리전 호출 방지)
#   - 재시도(backoff)로 일시 오류 대응
#   - 간단한 캐시로 동일 프롬프트 반복 호출 절감(비용/시간 감소)
# =============================================================================

import argparse
import json
import os
import time
import hashlib
from typing import Optional

import pandas as pd

try:
    import boto3
    from botocore.exceptions import ClientError
except Exception:
    boto3 = None
    ClientError = Exception


# -----------------------------
# CLI
# -----------------------------
parser = argparse.ArgumentParser()
parser.add_argument("--input", required=True, help="input csv path (findings-scored.csv)")
parser.add_argument("--output", required=True, help="output csv path (findings-scored-ai.csv)")
args = parser.parse_args()


# -----------------------------
# CSV I/O (인코딩 명시)
# - 윈도우/엑셀 호환을 생각하면 utf-8-sig가 가장 무난
# -----------------------------
DF_READ_ENCODING = os.getenv("CSV_READ_ENCODING", "utf-8")
DF_WRITE_ENCODING = os.getenv("CSV_WRITE_ENCODING", "utf-8-sig")

df = pd.read_csv(args.input, encoding=DF_READ_ENCODING)


# -----------------------------
# Bedrock 설정 (환경 변수로 오버라이드 가능)
# -----------------------------
DEFAULT_BEDROCK_REGION = "ap-northeast-2"
DEFAULT_MODEL_ID = "anthropic.claude-3-haiku-20240307-v1:0"

MODEL_ID = os.getenv("BEDROCK_MODEL_ID", DEFAULT_MODEL_ID)
BEDROCK_REGION = os.getenv("BEDROCK_REGION", DEFAULT_BEDROCK_REGION)

# Force Seoul region to avoid accidental non-Seoul calls
if BEDROCK_REGION != DEFAULT_BEDROCK_REGION:
    print(f"[Bedrock] Override region {BEDROCK_REGION} -> {DEFAULT_BEDROCK_REGION}")
    BEDROCK_REGION = DEFAULT_BEDROCK_REGION

MAX_TOKENS = int(os.getenv("BEDROCK_MAX_TOKENS", "256"))       # 응답 최대 토큰
TEMPERATURE = float(os.getenv("BEDROCK_TEMPERATURE", "0.2"))   # 낮게: 사실/간결 위주
USE_BEDROCK = os.getenv("USE_BEDROCK", "true").lower() == "true"

# 재시도 설정
MAX_RETRIES = int(os.getenv("BEDROCK_MAX_RETRIES", "3"))
BASE_BACKOFF_SEC = float(os.getenv("BEDROCK_BASE_BACKOFF_SEC", "0.8"))

# 간단 캐시(동일 프롬프트 반복 호출 절감)
ENABLE_CACHE = os.getenv("BEDROCK_ENABLE_CACHE", "true").lower() == "true"
_prompt_cache = {}


def _safe_str(x) -> str:
    """NaN/None 안전 문자열 변환"""
    if x is None:
        return ""
    try:
        # pandas NaN 처리
        if pd.isna(x):
            return ""
    except Exception:
        pass
    return str(x).strip()


def fallback_summary(row) -> str:
    """Bedrock 실패 시 룰 기반 요약(대체)"""
    title = _safe_str(row.get("check_title"))
    return f"Finding summary: {title}" if title else "Finding summary: N/A"


def fallback_rationale(row) -> str:
    """Bedrock 실패 시 룰 기반 우선순위 근거(대체)"""
    prio = _safe_str(row.get("priority")) or "P3"
    sev = _safe_str(row.get("severity")) or "medium"
    br = _safe_str(row.get("blast_radius")) or "3"
    return f"Priority {prio} based on severity={sev} and blast_radius={br}."


def get_bedrock_client():
    """bedrock-runtime 클라이언트 재사용(성능 개선)"""
    if not USE_BEDROCK or boto3 is None:
        return None
    return boto3.client("bedrock-runtime", region_name=BEDROCK_REGION)


def _cache_key(prompt: str) -> str:
    return hashlib.sha256(prompt.encode("utf-8")).hexdigest()


def call_bedrock(client, prompt: str) -> Optional[str]:
    """AWS Bedrock Claude 3 Haiku 호출(재시도 + 캐시)"""
    if client is None:
        return None

    if ENABLE_CACHE:
        ck = _cache_key(prompt)
        if ck in _prompt_cache:
            return _prompt_cache[ck]

    body = {
        "anthropic_version": "bedrock-2023-05-31",
        "max_tokens": MAX_TOKENS,
        "temperature": TEMPERATURE,
        "messages": [{"role": "user", "content": prompt}],
    }

    last_err = None
    for attempt in range(1, MAX_RETRIES + 1):
        try:
            resp = client.invoke_model(
                modelId=MODEL_ID,  # 보통은 short id 그대로 사용(arn 변환 강제 안 함)
                contentType="application/json",
                accept="application/json",
                body=json.dumps(body),
            )
            payload = json.loads(resp["body"].read())
            parts = payload.get("content", [])
            if not parts:
                return None
            text = (parts[0].get("text") or "").strip()
            if ENABLE_CACHE:
                _prompt_cache[ck] = text
            return text

        except ClientError as e:
            last_err = e
            # 일시적 오류 대비 backoff
            sleep_s = BASE_BACKOFF_SEC * (2 ** (attempt - 1))
            print(f"[Bedrock] ClientError (attempt {attempt}/{MAX_RETRIES}): {e} -> sleep {sleep_s:.1f}s")
            time.sleep(sleep_s)
        except Exception as e:
            last_err = e
            sleep_s = BASE_BACKOFF_SEC * (2 ** (attempt - 1))
            print(f"[Bedrock] Error (attempt {attempt}/{MAX_RETRIES}): {e} -> sleep {sleep_s:.1f}s")
            time.sleep(sleep_s)

    print(f"[Bedrock] Failed after {MAX_RETRIES} retries. Last error: {last_err}")
    return None


def make_prompt(row, kind: str) -> str:
    """finding 데이터를 기반으로 Claude 프롬프트 생성"""
    title = _safe_str(row.get("check_title"))
    severity = _safe_str(row.get("severity"))
    prio = _safe_str(row.get("priority"))
    risk = _safe_str(row.get("risk_score"))
    blast_radius = _safe_str(row.get("blast_radius"))
    desc = _safe_str(row.get("recommendation_text"))

    if kind == "summary":
        return (
            "Summarize this security finding in 1-2 sentences for a security report. "
            "Be concise and factual. Do not invent details.\n"
            f"Title: {title}\n"
            f"Severity: {severity}\n"
            f"Risk score: {risk}\n"
            f"Recommendation/Details: {desc}"
        )

    return (
        "Explain why this priority was assigned in 1 sentence. "
        "Reference severity and blast radius. Be factual.\n"
        f"Title: {title}\n"
        f"Severity: {severity}\n"
        f"Priority: {prio}\n"
        f"Risk score: {risk}\n"
        f"Blast radius: {blast_radius}"
    )


# -----------------------------
# 실행
# -----------------------------
client = get_bedrock_client()

summaries = []
rationales = []

for _, row in df.iterrows():
    s = call_bedrock(client, make_prompt(row, "summary")) or fallback_summary(row)
    r = call_bedrock(client, make_prompt(row, "rationale")) or fallback_rationale(row)
    summaries.append(s)
    rationales.append(r)

df["ai_summary"] = summaries
df["ai_priority_rationale"] = rationales

df.to_csv(args.output, index=False, encoding=DF_WRITE_ENCODING)
print(f"[OK] Wrote: {args.output}")
