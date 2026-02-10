#!/usr/bin/env bash
set -euo pipefail

# Preflight AWS resources for Prowler remediation apply.
# This script is idempotent and safe to re-run.
#
# NOTE:
# - Requires AWS CLI configured with permissions in the target account.
# - Creates S3 buckets and DynamoDB table (may incur small costs).
# - Creates/starts a CloudTrail named in TRAIL_NAME if missing.

REGION="${REGION:-ap-northeast-2}"
ACCOUNT_ID_EXPECTED="${ACCOUNT_ID_EXPECTED:-132410971304}"

TRAIL_NAME="${TRAIL_NAME:-security-cloudtrail}"
CLOUDTRAIL_BUCKET="${CLOUDTRAIL_BUCKET:-aws-cloudtrail-logs-132410971304-0971c04b}"
LOG_BUCKET="${LOG_BUCKET:-${CLOUDTRAIL_BUCKET}-logs}"

TF_BACKEND_BUCKET="${TF_BACKEND_BUCKET:-prowler-terraform-state-132410971304}"
TF_BACKEND_TABLE="${TF_BACKEND_TABLE:-prowler-terraform-locks}"

echo "== Checking AWS identity =="
ACCOUNT_ID_ACTUAL="$(aws sts get-caller-identity --query Account --output text)"
if [[ "${ACCOUNT_ID_ACTUAL}" != "${ACCOUNT_ID_EXPECTED}" ]]; then
  echo "ERROR: AWS account mismatch. Expected ${ACCOUNT_ID_EXPECTED}, got ${ACCOUNT_ID_ACTUAL}."
  exit 1
fi
echo "OK: account ${ACCOUNT_ID_ACTUAL}"

echo "== Ensuring Terraform backend bucket =="
aws s3api head-bucket --bucket "${TF_BACKEND_BUCKET}" >/dev/null 2>&1 || \
aws s3api create-bucket \
  --bucket "${TF_BACKEND_BUCKET}" \
  --region "${REGION}" \
  --create-bucket-configuration LocationConstraint="${REGION}"

aws s3api put-bucket-versioning \
  --bucket "${TF_BACKEND_BUCKET}" \
  --versioning-configuration Status=Enabled

aws s3api put-public-access-block \
  --bucket "${TF_BACKEND_BUCKET}" \
  --public-access-block-configuration \
  BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

echo "== Ensuring DynamoDB lock table =="
aws dynamodb describe-table --table-name "${TF_BACKEND_TABLE}" >/dev/null 2>&1 || \
aws dynamodb create-table \
  --table-name "${TF_BACKEND_TABLE}" \
  --billing-mode PAY_PER_REQUEST \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH

echo "== Ensuring CloudTrail buckets =="
aws s3api head-bucket --bucket "${CLOUDTRAIL_BUCKET}" >/dev/null 2>&1 || \
aws s3api create-bucket \
  --bucket "${CLOUDTRAIL_BUCKET}" \
  --region "${REGION}" \
  --create-bucket-configuration LocationConstraint="${REGION}"

aws s3api head-bucket --bucket "${LOG_BUCKET}" >/dev/null 2>&1 || \
aws s3api create-bucket \
  --bucket "${LOG_BUCKET}" \
  --region "${REGION}" \
  --create-bucket-configuration LocationConstraint="${REGION}"

echo "== Ensuring CloudTrail trail =="
aws cloudtrail get-trail --name "${TRAIL_NAME}" >/dev/null 2>&1 || \
aws cloudtrail create-trail \
  --name "${TRAIL_NAME}" \
  --s3-bucket-name "${CLOUDTRAIL_BUCKET}" \
  --is-multi-region-trail

aws cloudtrail start-logging --name "${TRAIL_NAME}"

echo "== Ensuring IAM user used by remediation =="
aws iam get-user --user-name aws_learner >/dev/null 2>&1 || \
aws iam create-user --user-name aws_learner

echo "Preflight complete."
