#!/usr/bin/env bash
# preflight_discovery.sh — AWS 리소스 사전 탐색
# 기존 AWS 리소스를 조회하여 JSON 캐시 파일 생성
# terraform apply 전에 import/skip 결정에 사용
set -euo pipefail

OUTFILE="${1:-/tmp/aws_discovery.json}"
REGION="${AWS_REGION:-ap-northeast-2}"

echo "Running pre-flight AWS discovery (region=$REGION)..."

# ── CloudTrail ──────────────────────────────────────
trails=$(aws cloudtrail describe-trails --region "$REGION" \
  --query 'trailList[].{Name:Name,TrailARN:TrailARN,S3BucketName:S3BucketName,IsMultiRegion:IsMultiRegionTrail,HomeRegion:HomeRegion,CloudWatchLogsLogGroupArn:CloudWatchLogsLogGroupArn}' \
  --output json 2>/dev/null || echo '[]')

# ── Config Recorder ─────────────────────────────────
config_recorders=$(aws configservice describe-configuration-recorders --region "$REGION" \
  --query 'ConfigurationRecorders[].{name:name,roleARN:roleARN}' \
  --output json 2>/dev/null || echo '[]')

config_channels=$(aws configservice describe-delivery-channels --region "$REGION" \
  --query 'DeliveryChannels[].{name:name,s3BucketName:s3BucketName}' \
  --output json 2>/dev/null || echo '[]')

# ── GuardDuty ───────────────────────────────────────
guardduty_detectors=$(aws guardduty list-detectors --region "$REGION" \
  --query 'DetectorIds' --output json 2>/dev/null || echo '[]')

# ── SecurityHub ─────────────────────────────────────
securityhub_enabled="false"
if aws securityhub describe-hub --region "$REGION" >/dev/null 2>&1; then
  securityhub_enabled="true"
fi

# ── Organizations ───────────────────────────────────
org_info=$(aws organizations describe-organization \
  --query 'Organization.{Id:Id,MasterAccountId:MasterAccountId}' \
  --output json 2>/dev/null || echo 'null')

# ── KMS Keys ───────────────────────────────────────
kms_aliases=$(aws kms list-aliases --region "$REGION" \
  --query 'Aliases[].{AliasName:AliasName,TargetKeyId:TargetKeyId}' \
  --output json 2>/dev/null || echo '[]')

kms_keys=$(aws kms list-keys --region "$REGION" \
  --query 'Keys[].KeyId' --output json 2>/dev/null || echo '[]')

# ── Service-Linked Roles ───────────────────────────
slr_services=("config.amazonaws.com" "guardduty.amazonaws.com" "securityhub.amazonaws.com" \
              "cloudtrail.amazonaws.com" "ssm.amazonaws.com" "kms.amazonaws.com" \
              "mrk.kms.amazonaws.com" "elasticloadbalancing.amazonaws.com")

slr_status="{"
first=true
for svc in "${slr_services[@]}"; do
  role_name="AWSServiceRoleFor$(echo "$svc" | cut -d'.' -f1 | sed 's/.*/\u&/')"
  # more reliable: just check if the SLR role path exists
  exists="false"
  if aws iam list-roles --path-prefix /aws-service-role/"$svc"/ \
      --query 'Roles[0].RoleName' --output text 2>/dev/null | grep -qv '^None$'; then
    exists="true"
  fi
  $first || slr_status="$slr_status,"
  slr_status="$slr_status \"$svc\": $exists"
  first=false
done
slr_status="$slr_status }"

# ── IAM Password Policy ────────────────────────────
password_policy_exists="false"
if aws iam get-account-password-policy >/dev/null 2>&1; then
  password_policy_exists="true"
fi

# ── Account ID ──────────────────────────────────────
account_id=$(aws sts get-caller-identity --query 'Account' --output text 2>/dev/null || echo "unknown")

# ── CloudWatch Log Groups ─────────────────────────
cw_log_groups=$(aws logs describe-log-groups --region "$REGION" \
  --query 'logGroups[].logGroupName' --output json 2>/dev/null || echo '[]')

# ── VPC ───────────────────────────────────────────
vpc_ids=$(aws ec2 describe-vpcs --region "$REGION" \
  --query 'Vpcs[].VpcId' --output json 2>/dev/null || echo '[]')

# ── Subnets ────────────────────────────────────────
subnet_ids=$(aws ec2 describe-subnets --region "$REGION" \
  --query 'Subnets[].SubnetId' --output json 2>/dev/null || echo '[]')

# ── S3 Buckets (existing, for import) ──────────────
s3_buckets=$(aws s3api list-buckets --query 'Buckets[].Name' --output json 2>/dev/null || echo '[]')

# ── Write JSON ──────────────────────────────────────
cat > "$OUTFILE" <<ENDJSON
{
  "region": "$REGION",
  "account_id": "$account_id",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "cloudtrail": {
    "trails": $trails
  },
  "config": {
    "recorders": $config_recorders,
    "delivery_channels": $config_channels
  },
  "guardduty": {
    "detector_ids": $guardduty_detectors
  },
  "securityhub": {
    "enabled": $securityhub_enabled
  },
  "organizations": $org_info,
  "kms": {
    "aliases": $kms_aliases,
    "key_ids": $kms_keys
  },
  "service_linked_roles": $slr_status,
  "iam": {
    "password_policy_exists": $password_policy_exists
  },
  "cloudwatch": {
    "log_groups": $cw_log_groups
  },
  "vpc": {
    "vpcs": $vpc_ids,
    "subnets": $subnet_ids
  },
  "s3": {
    "buckets": $s3_buckets
  }
}
ENDJSON

echo "Discovery complete → $OUTFILE"
cat "$OUTFILE" | python3 -m json.tool --no-ensure-ascii 2>/dev/null | head -5
echo "..."
