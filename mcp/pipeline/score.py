# =============================================================================
# score.py - 위험도 점수 산정 + 자동 수정 가능성 분류 스크립트 (AUTO-REMEDIATION AWARE)
# =============================================================================
# 입력:  mcp/output/findings-normalized.csv
# 출력:  mcp/output/findings-scored.csv
#
# 추가 기능:
# - remediation_class 분류 (자동수정 가능 여부)
# - execution_model 자동 결정 (Auto / Review / Manual)
#
# Auto 적용 조건:
# priority >= P2 AND remediation_class == PATCH_SAFE
# =============================================================================

import argparse
import pandas as pd

parser = argparse.ArgumentParser()
parser.add_argument("--input", required=True)
parser.add_argument("--output", required=True)
args = parser.parse_args()

df = pd.read_csv(args.input)

# ---------------- 위험도 계산 가중치 ----------------

sev = {"low": 2, "medium": 3, "high": 4, "critical": 5}
dc  = {"public": 1.0, "internal": 1.1, "confidential": 1.2, "regulated": 1.3}
env = {"prod": 1.2, "non-prod": 1.0, "unknown": 1.1}

# ---------------- 자동 수정 가능 체크 분류 ----------------

# Terraform으로 안전하게 적용 가능한 단독 설정 변경
PATCH_SAFE_KEYWORDS = [
    "encryption",
    "logging",
    "log_metric",
    "retention",
    "mfa_delete",
    "versioning",
    "secure_transport",
    "password_policy",
    "cloudtrail",       # cloudtrail_log_file_validation, cloudtrail_multi_region 등
    "guardduty",        # guardduty_is_enabled 등
    "securityhub",      # securityhub_enabled 등
    "config_recorder",  # config recorder/delivery channel 활성화
    "alarm",
]

# Terraform 적용 가능하지만 기존 리소스 변경이 필요해 검토 필요
PATCH_RISKY_KEYWORDS = [
    "security_group",
    "network_acl",
    "policy",
    "kms_key_rotation",
    "kms_cmk",
]

# Terraform으로 해결 불가 또는 인프라 설계 결정이 필요한 항목
MANUAL_KEYWORDS = [
    "vpc_different",
    "vpc_subnet",
    "route_table",
    "peering",
    "backup_plan",
    "organizations",
    "root_mfa",
    "iam_user",
    "access_key",
    "instance_profile",
    "public_ip",
    "flow_logs",
]


def classify_remediation(check_id: str) -> str:
    cid = str(check_id).lower()
    if any(k in cid for k in MANUAL_KEYWORDS):
        return "MANUAL_REQUIRED"
    if any(k in cid for k in PATCH_RISKY_KEYWORDS):
        return "PATCH_RISKY"
    if any(k in cid for k in PATCH_SAFE_KEYWORDS):
        return "PATCH_SAFE"
    return "MANUAL_REQUIRED"


# ---------------- 위험도 점수 ----------------

def score(row):
    impact = float(row.get("business_criticality", 3))
    likelihood = sev.get(str(row.get("severity", "medium")).lower(), 3)
    exposure = float(row.get("blast_radius", 3)) + (
        1 if str(row.get("internet_exposed", "no")).lower() == "yes" else 0
    )
    mult = (
        dc.get(str(row.get("data_class", "internal")).lower(), 1.1)
        * env.get(str(row.get("environment", "prod")).lower(), 1.1)
    )
    cc = float(row.get("compensating_controls", 0))
    return round((impact * likelihood * exposure * mult) - cc, 2)


def prio(val):
    if val >= 90:
        return "P0"
    if val >= 60:
        return "P1"
    if val >= 30:
        return "P2"
    return "P3"


# ---------------- 실행 모델 결정 ----------------

def execution_model(priority, remediation_class):
    # 운영 안전 가드레일: 고위험은 수동 검토
    if priority in ("P0", "P1"):
        return "Manual"
    if priority == "P2" and remediation_class == "PATCH_SAFE":
        return "Auto"
    if remediation_class == "PATCH_RISKY":
        return "Review"
    return "Manual"


# ---------------- 계산 실행 ----------------

df["risk_score"] = df.apply(score, axis=1)
df["priority"] = df["risk_score"].apply(prio)
df["remediation_class"] = df["check_id"].apply(classify_remediation)
df["execution_model"] = df.apply(
    lambda r: execution_model(r["priority"], r["remediation_class"]), axis=1
)

df.to_csv(args.output, index=False)
