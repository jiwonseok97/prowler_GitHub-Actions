import argparse
import pandas as pd

parser = argparse.ArgumentParser()
parser.add_argument("--input", required=True)
parser.add_argument("--template", required=True)
parser.add_argument("--output", required=True)
args = parser.parse_args()

df = pd.read_csv(args.input)
with open(args.template, "r", encoding="utf-8") as f:
    tpl = f.read()

blocks = []
for _, r in df.iterrows():
    block = tpl
    for k in ["check_id", "check_title", "priority", "risk_score", "execution_model", "remediation_url", "ai_summary", "ai_priority_rationale"]:
        block = block.replace("{{" + k + "}}", str(r.get(k, "")))
    blocks.append(block)

with open(args.output, "w", encoding="utf-8") as f:
    f.write("\n\n".join(blocks))
