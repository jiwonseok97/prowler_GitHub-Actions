# =============================================================================
# score.py - 위험도 점수 산정 및 우선순위 분류 스크립트
# =============================================================================
# 역할: 정규화된 finding에 대해 다중 요소 기반 위험도 점수를 계산하고 우선순위 부여
# 입력: mcp/output/findings-normalized.csv
# 출력: mcp/output/findings-scored.csv (risk_score, priority 컬럼 추가)
#
# 위험도 공식:
#   risk_score = (impact × likelihood × exposure × multiplier) - compensating_controls
#
# 우선순위 기준:
#   P0: 90점 이상 (즉시 대응)
#   P1: 60점 이상 (긴급)
#   P2: 30점 이상 (중요) → generate_remediation.py에서 자동 코드 생성 대상
#   P3: 30점 미만 (낮음) → 수동 대응
# =============================================================================

import argparse
import pandas as pd

parser = argparse.ArgumentParser()
parser.add_argument("--input", required=True)
parser.add_argument("--output", required=True)
args = parser.parse_args()

df = pd.read_csv(args.input)

# --- 가중치 매핑 테이블 ---
sev = {"low": 2, "medium": 3, "high": 4, "critical": 5}          # 심각도 → 발생 가능성 점수
dc = {"public": 1.0, "internal": 1.1, "confidential": 1.2, "regulated": 1.3}  # 데이터 등급 배수
env = {"prod": 1.2, "non-prod": 1.0, "unknown": 1.1}             # 환경 배수


def score(row):
    """다중 요소 기반 위험도 점수 계산"""
    impact = float(row.get("business_criticality", 3))       # 사업 영향도
    likelihood = sev.get(str(row.get("severity", "medium")).lower(), 3)  # 발생 가능성 (심각도 기반)
    # 노출도 = 영향 범위 + 인터넷 노출 시 +1
    exposure = float(row.get("blast_radius", 3)) + (1 if str(row.get("internet_exposed", "no")).lower() == "yes" else 0)
    # 배수 = 데이터 등급 × 환경 가중치
    mult = dc.get(str(row.get("data_class", "internal")).lower(), 1.1) * env.get(str(row.get("environment", "prod")).lower(), 1.1)
    cc = float(row.get("compensating_controls", 0))          # 보상 통제 (위험도 감소 요소)
    return round((impact * likelihood * exposure * mult) - cc, 2)


def prio(val):
    """위험도 점수 → 우선순위 등급 변환"""
    if val >= 90:
        return "P0"  # 즉시 대응
    if val >= 60:
        return "P1"  # 긴급
    if val >= 30:
        return "P2"  # 중요
    return "P3"      # 낮음


# 각 finding에 위험도 점수 및 우선순위 부여
risk_scores = df.apply(score, axis=1)
df["risk_score"] = risk_scores
df["priority"] = risk_scores.apply(prio)

# 실행 모델 컬럼 (Manual: 수동 대응 / Auto: 자동 적용)
if "execution_model" not in df.columns:
    df["execution_model"] = "Manual"
else:
    df["execution_model"] = df["execution_model"].fillna("Manual")

df.to_csv(args.output, index=False)
