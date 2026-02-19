import argparse
import pandas as pd


parser = argparse.ArgumentParser()
parser.add_argument("--input", required=True)
parser.add_argument("--output", required=True)
args = parser.parse_args()

df = pd.read_csv(args.input)

sev = {"low": 2, "medium": 3, "high": 4, "critical": 5}
dc = {"public": 1.0, "internal": 1.1, "confidential": 1.2, "regulated": 1.3}
env = {"prod": 1.2, "non-prod": 1.0, "unknown": 1.1}

# Explicitly non-automatable by Terraform in this pipeline.
MANUAL_ONLY_CHECK_IDS = {
    "iam_user_accesskey_rotation_90d",
    "iam_root_mfa_enabled",
    "iam_root_hardware_mfa_enabled",
    "s3_bucket_no_mfa_delete",
    "cloudtrail_bucket_requires_mfa_delete",
    "cloudwatch_log_group_no_secrets_in_logs",
    "cloudwatch_log_group_kms_encryption_enabled",
}

# Risky: technically possible but can break access/traffic without review.
PATCH_RISKY_CHECK_IDS = {
    "ec2_securitygroup_allow_ingress_from_internet_to_all_ports",
    "ec2_securitygroup_allow_ingress_from_internet_to_tcp_port_22",
    "ec2_securitygroup_allow_ingress_from_internet_to_tcp_port_3389",
    "ec2_networkacl_allow_ingress_any_port",
    "ec2_networkacl_allow_ingress_tcp_port_22",
    "ec2_networkacl_allow_ingress_tcp_port_3389",
}

# Strongly automatable controls in current Terraform flow.
PATCH_SAFE_PREFIXES = (
    "cloudtrail_",
    "cloudwatch_",
    "s3_",
    "kms_",
)

PATCH_SAFE_KEYWORDS = (
    "password_policy",
    "versioning",
    "secure_transport",
    "encryption",
    "log_metric",
    "retention",
    "flow_logs",
)


def classify_remediation(check_id: str) -> str:
    cid = str(check_id).strip().lower()
    if not cid or cid in {"nan", "none"}:
        return "MANUAL_REQUIRED"
    if cid in MANUAL_ONLY_CHECK_IDS:
        return "MANUAL_REQUIRED"
    if cid in PATCH_RISKY_CHECK_IDS:
        return "PATCH_RISKY"
    if cid.startswith(PATCH_SAFE_PREFIXES):
        return "PATCH_SAFE"
    if any(k in cid for k in PATCH_SAFE_KEYWORDS):
        return "PATCH_SAFE"
    if "security_group" in cid or "network_acl" in cid:
        return "PATCH_RISKY"
    return "MANUAL_REQUIRED"


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


def execution_model(priority, remediation_class):
    if priority in ("P0", "P1"):
        return "Manual"
    if priority == "P2" and remediation_class == "PATCH_SAFE":
        return "Auto"
    if remediation_class == "PATCH_RISKY":
        return "Review"
    return "Manual"


df["risk_score"] = df.apply(score, axis=1)
df["priority"] = df["risk_score"].apply(prio)
df["remediation_class"] = df["check_id"].apply(classify_remediation)
df["execution_model"] = df.apply(
    lambda r: execution_model(r["priority"], r["remediation_class"]), axis=1
)

df.to_csv(args.output, index=False)
