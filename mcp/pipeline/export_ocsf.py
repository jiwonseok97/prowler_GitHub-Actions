# =============================================================================
# export_ocsf.py - OCSF 표준 포맷 내보내기 스크립트
# =============================================================================
# 역할: Prowler가 생성한 OCSF(Open Cybersecurity Schema Framework) JSON 파일 중
#       가장 최신 파일을 표준 출력 경로로 복사
# 입력: output/*.ocsf.json (Prowler OCSF 출력)
# 출력: mcp/output/ocsf-findings.json
#
# OCSF는 보안 도구 간 데이터 교환을 위한 표준 스키마로,
# SIEM, SOAR 등 다른 보안 플랫폼과의 연동에 사용
# =============================================================================

import argparse
import glob
import os
import shutil

parser = argparse.ArgumentParser()
parser.add_argument("--input", required=True, help="Input OCSF glob, e.g. output/*.ocsf.json")
parser.add_argument("--output", required=True, help="Output path for latest OCSF JSON")
args = parser.parse_args()

# OCSF JSON 파일 검색
files = glob.glob(args.input)
if not files:
    raise SystemExit(f"No OCSF files matched: {args.input}")

# 가장 최근 수정된 파일 선택 후 표준 경로로 복사
latest = max(files, key=os.path.getmtime)
os.makedirs(os.path.dirname(args.output), exist_ok=True)
shutil.copyfile(latest, args.output)
