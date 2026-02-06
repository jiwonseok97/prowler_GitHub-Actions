# =============================================================================
# normalize.py - Prowler 원본 CSV 정규화 스크립트
# =============================================================================
# 역할: Prowler가 출력한 CSV(세미콜론 구분)를 표준화된 컬럼 구조로 변환
# 입력: output/*.csv (Prowler 원본 스캔 결과)
# 출력: mcp/output/findings-normalized.csv
#
# 주요 기능:
#   1) 대문자 컬럼명(FINDING_UID 등) → 소문자 표준 컬럼명으로 매핑
#   2) COMPLIANCE 필드에서 CIS, KISA-ISMS-P, AWS Well-Architected 프레임워크 분리 추출
#   3) 후속 스크립트(score.py)에서 사용할 위험도 산정 기본값 설정
# =============================================================================

import argparse
import glob
import os
import pandas as pd

parser = argparse.ArgumentParser()
parser.add_argument("--input", required=True, help="Input CSV glob, e.g. output/*.csv")
parser.add_argument("--output", required=True, help="Output normalized CSV")
args = parser.parse_args()

# Prowler CSV 파일 검색 (glob 패턴으로 여러 파일 매칭 가능)
files = glob.glob(args.input)
if not files:
    raise SystemExit(f"No input files matched: {args.input}")

# 여러 CSV 파일을 하나의 DataFrame으로 병합
frames = []
for f in files:
    frames.append(pd.read_csv(f, sep=";"))  # Prowler CSV는 세미콜론(;) 구분자 사용

_df = pd.concat(frames, ignore_index=True)


def pick_compliance(text, prefix):
    """COMPLIANCE 필드에서 특정 프레임워크(CIS, ISMS-P 등)에 해당하는 항목만 추출"""
    if pd.isna(text):
        return ""
    items = [x.strip() for x in str(text).split("|")]
    return "; ".join([x for x in items if x.startswith(prefix)])


# 표준화된 컬럼 구조로 변환
out = pd.DataFrame({
    # --- Prowler 원본 데이터 매핑 ---
    "finding_uid": _df.get("FINDING_UID"),           # 고유 식별자
    "check_id": _df.get("CHECK_ID"),                 # 점검 항목 ID (예: s3_bucket_default_encryption)
    "check_title": _df.get("CHECK_TITLE"),           # 점검 항목 제목
    "status": _df.get("STATUS"),                     # 결과 상태 (PASS/FAIL)
    "severity": _df.get("SEVERITY"),                 # 심각도 (low/medium/high/critical)
    "service_name": _df.get("SERVICE_NAME"),         # AWS 서비스명 (s3, iam, ec2 등)
    "region": _df.get("REGION"),                     # AWS 리전
    "resource_uid": _df.get("RESOURCE_UID"),         # 대상 리소스 고유 식별자

    # --- 컴플라이언스 프레임워크별 분리 ---
    "cis": _df.get("COMPLIANCE").apply(lambda x: pick_compliance(x, "CIS-")),
    "isms_p": _df.get("COMPLIANCE").apply(lambda x: pick_compliance(x, "KISA-ISMS-P-2023")),
    "wa_security_pillar": _df.get("COMPLIANCE").apply(lambda x: pick_compliance(x, "AWS-Well-Architected-Framework-Security-Pillar")),

    # --- 조치 가이드 ---
    "remediation_url": _df.get("REMEDIATION_RECOMMENDATION_URL"),    # 조치 참고 URL
    "recommendation_text": _df.get("REMEDIATION_RECOMMENDATION_TEXT"),  # 조치 권고 텍스트

    # --- 위험도 산정용 기본값 (score.py에서 사용) ---
    "risk_owner": "security",          # 리스크 담당: 보안팀
    "business_criticality": 3,         # 사업 중요도 (1~5, 기본 3)
    "data_class": "internal",          # 데이터 등급 (public/internal/confidential/regulated)
    "compensating_controls": 0,        # 보상 통제 점수 (위험도에서 차감)
    "blast_radius": 3,                 # 영향 범위 (1~5, 기본 3)
    "environment": "prod",             # 환경 (prod/non-prod/unknown)
    "internet_exposed": "no",          # 인터넷 노출 여부 (yes/no)
})

os.makedirs(os.path.dirname(args.output), exist_ok=True)
out.to_csv(args.output, index=False)
