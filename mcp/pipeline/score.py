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


def score(row):
    impact = float(row.get("business_criticality", 3))
    likelihood = sev.get(str(row.get("severity", "medium")).lower(), 3)
    exposure = float(row.get("blast_radius", 3)) + (1 if str(row.get("internet_exposed", "no")).lower() == "yes" else 0)
    mult = dc.get(str(row.get("data_class", "internal")).lower(), 1.1) * env.get(str(row.get("environment", "prod")).lower(), 1.1)
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


risk_scores = df.apply(score, axis=1)
df["risk_score"] = risk_scores
df["priority"] = risk_scores.apply(prio)
if "execution_model" not in df.columns:
    df["execution_model"] = "Manual"
else:
    df["execution_model"] = df["execution_model"].fillna("Manual")

df.to_csv(args.output, index=False)
