# Prowler Auto-Remediation Pipeline

이 저장소는 Prowler 결과를 기반으로 Terraform 보완 코드를 생성하고, 카테고리별 PR/merge/apply까지 자동화합니다.

## End-to-End 구조

1. `prowler-security-scan.yml`
- `1) Scan`: AWS 계정 스캔(CIS 1.4), 원본 산출물 업로드
- `2) Process`: Normalize/Score/AI Assist/Runbook/OCSF 생성
- `3) Remediate`: Terraform remediation 생성 + 카테고리별 PR 생성/업데이트

2. `apply-remediation.yml`
- `plan` job: PR 기준 Terraform plan/품질 게이트/코멘트
- `apply` job: PR merge 이후 AWS 실제 리소스에 apply

## 브랜치/PR 정책

- 카테고리별 고정 브랜치 사용:
- `remediation/cloudtrail`
- `remediation/cloudwatch`
- `remediation/iam`
- `remediation/kms`
- `remediation/s3`
- `remediation/network-ec2-vpc`

- 동작 방식:
- 같은 카테고리의 새 결과는 기존 브랜치에 `--force-with-lease` 푸시
- 해당 브랜치의 open PR이 있으면 `gh pr edit`로 갱신
- 없으면 새 PR 생성

즉, 타임스탬프 브랜치(`remediation/<category>-<runid>-<attempt>`)를 더 이상 만들지 않습니다.

## 카테고리별 머지 권장 순서

1. `cloudtrail`
2. `cloudwatch`
3. `s3`
4. `kms`
5. `iam` / `network-ec2-vpc` (운영 영향 검토 후)

`cloudwatch`는 CloudTrail의 CloudWatch Logs 연결이 먼저 반영되어야 PASS 판정이 안정적입니다.

## 실제 반영(Apply) 실패 시 핵심 점검

1. `terraform init/validate/plan` 실패 여부
2. `iac/scripts/generate_tfvars.py`가 discovery 기반 값을 제대로 채웠는지
3. `iac/scripts/auto_import.sh` import 성공 여부
4. `iac/scripts/resilient_apply.sh` 재시도 후 최종 실패 원인

### 최근 수정 사항(CloudTrail KMS)

- 증상: `kms_key_id`가 UUID만 들어가 CloudTrail에서 `invalid ARN` 오류
- 조치: `iac/scripts/generate_tfvars.py`에서 CloudTrail용 `kms_key_id`를 ARN 형식으로 정규화
- 결과: 동일 유형의 apply 실패 재발 방지

## 운영 체크리스트

1. remediation PR merge 전 `plan` job 통과 확인
2. `cloudtrail` 먼저 merge
3. `apply-remediation` 성공 확인 후 `cloudwatch` merge
4. apply 후 Prowler 재스캔 결과에서 대상 check 감소 확인
