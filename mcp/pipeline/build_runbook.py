# =============================================================================
# build_runbook.py - 운영 런북 자동 생성 스크립트
# =============================================================================
# 역할: 마크다운 템플릿에 finding 데이터를 주입하여 조치 런북 문서 생성
# 입력: mcp/output/findings-scored-ai.csv + mcp/templates/runbook.md (템플릿)
# 출력: mcp/output/runbook.md
#
# 템플릿 변수 치환:
#   {{check_id}}, {{check_title}}, {{priority}}, {{risk_score}},
#   {{execution_model}}, {{remediation_url}}, {{ai_summary}},
#   {{ai_priority_rationale}}
# =============================================================================

import argparse
import pandas as pd

parser = argparse.ArgumentParser()
parser.add_argument("--input", required=True)
parser.add_argument("--template", required=True)
parser.add_argument("--output", required=True)
args = parser.parse_args()

df = pd.read_csv(args.input)

# 런북 마크다운 템플릿 로드
with open(args.template, "r", encoding="utf-8") as f:
    tpl = f.read()

# 각 finding별로 템플릿의 {{변수}}를 실제 데이터로 치환
blocks = []
for _, r in df.iterrows():
    block = tpl
    for k in ["check_id", "check_title", "priority", "risk_score", "execution_model", "remediation_url", "ai_summary", "ai_priority_rationale"]:
        block = block.replace("{{" + k + "}}", str(r.get(k, "")))
    blocks.append(block)

# finding별 런북 블록을 하나의 문서로 합침
with open(args.output, "w", encoding="utf-8") as f:
    f.write("\n\n".join(blocks))
