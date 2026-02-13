# =============================================================================
# normalize.py - Normalize Prowler CSV into a consistent schema
# =============================================================================

import argparse
import glob
import os
import pandas as pd

parser = argparse.ArgumentParser()
parser.add_argument("--input", required=True, help="Input CSV glob, e.g. output/*.csv")
parser.add_argument("--output", required=True, help="Output normalized CSV")
args = parser.parse_args()

files = glob.glob(args.input)
if not files:
    raise SystemExit(f"No input files matched: {args.input}")

frames = []
for f in files:
    frames.append(pd.read_csv(f, sep=";"))

_df = pd.concat(frames, ignore_index=True)


def pick_compliance(text, prefix):
    if pd.isna(text):
        return ""
    items = [x.strip() for x in str(text).split("|")]
    return "; ".join([x for x in items if x.startswith(prefix)])


out = pd.DataFrame({
    # Prowler fields
    "finding_uid": _df.get("FINDING_UID"),
    "check_id": _df.get("CHECK_ID"),
    "check_title": _df.get("CHECK_TITLE"),
    "status": _df.get("STATUS"),
    "severity": _df.get("SEVERITY"),
    "service_name": _df.get("SERVICE_NAME"),
    "region": _df.get("REGION"),
    "resource_uid": _df.get("RESOURCE_UID"),
    "resource_arn": _df.get("RESOURCE_ARN"),
    "resource_name": _df.get("RESOURCE_NAME"),
    "resource_id": _df.get("RESOURCE_ID"),
    "resource_type": _df.get("RESOURCE_TYPE"),
    "account_id": _df.get("ACCOUNT_ID"),

    # Compliance split
    "cis": _df.get("COMPLIANCE").apply(lambda x: pick_compliance(x, "CIS-")),
    "isms_p": _df.get("COMPLIANCE").apply(lambda x: pick_compliance(x, "KISA-ISMS-P-2023")),
    "wa_security_pillar": _df.get("COMPLIANCE").apply(
        lambda x: pick_compliance(x, "AWS-Well-Architected-Framework-Security-Pillar")
    ),

    # Remediation guidance
    "remediation_url": _df.get("REMEDIATION_RECOMMENDATION_URL"),
    "recommendation_text": _df.get("REMEDIATION_RECOMMENDATION_TEXT"),

    # Risk scoring defaults (score.py uses these)
    "risk_owner": "security",
    "business_criticality": 3,
    "data_class": "internal",
    "compensating_controls": 0,
    "blast_radius": 3,
    "environment": "prod",
    "internet_exposed": "no",
})

os.makedirs(os.path.dirname(args.output), exist_ok=True)
out.to_csv(args.output, index=False)
