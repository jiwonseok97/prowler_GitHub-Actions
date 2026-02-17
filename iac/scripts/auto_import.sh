#!/usr/bin/env bash
# auto_import.sh — 기존 AWS 리소스를 terraform state로 자동 import
# Usage: auto_import.sh <work_dir> <discovery_json>
set -euo pipefail

WORK_DIR="${1:?Usage: auto_import.sh <work_dir> <discovery_json>}"
DISCOVERY="${2:-/tmp/aws_discovery.json}"

if [ ! -f "$DISCOVERY" ]; then
  echo "WARN: Discovery file not found: $DISCOVERY — skipping auto-import"
  exit 0
fi

REGION=$(python3 -c "import json; print(json.load(open('$DISCOVERY'))['region'])" 2>/dev/null || echo "ap-northeast-2")
ACCOUNT=$(python3 -c "import json; print(json.load(open('$DISCOVERY'))['account_id'])" 2>/dev/null || echo "unknown")

imported=0
skipped=0
failed=0
blocked=0

import_resource() {
  local addr="$1"
  local id="$2"

  # 이미 state에 있으면 skip
  if terraform -chdir="$WORK_DIR" state show "$addr" >/dev/null 2>&1; then
    echo "  SKIP import $addr (already in state)"
    skipped=$((skipped+1))
    return 0
  fi

  # 코드에 해당 resource가 없으면 skip
  local rtype=$(echo "$addr" | cut -d'.' -f1)
  local rname=$(echo "$addr" | cut -d'.' -f2)
  if ! grep -rEq "resource\s+\"$rtype\"\s+\"$rname\"" "$WORK_DIR"/*.tf 2>/dev/null; then
    echo "  SKIP import $addr (resource not declared in .tf files)"
    return 0
  fi

  echo "  IMPORT $addr ← $id"
  import_err=$(mktemp)
  if terraform -chdir="$WORK_DIR" import -input=false "$addr" "$id" 2>&1 | tee "$import_err"; then
    imported=$((imported+1))
    rm -f "$import_err"
    return 0
  fi

  # Import failed — determine if the resource exists in AWS
  # "Cannot import non-existent" or "not found" = resource doesn't exist → safe to skip
  if grep -qiE '(Cannot import non-existent|not found|does not exist|NoSuchEntity|NoSuchBucket|NotFoundException)' "$import_err" 2>/dev/null; then
    echo "  WARN: import skipped for $addr — resource $id does not exist in AWS"
    failed=$((failed+1))
    rm -f "$import_err"
    return 0
  fi

  # Resource exists in AWS but import failed → BLOCKING error
  # Apply would try to create a duplicate, causing conflict
  echo "  BLOCK: import FAILED for $addr with id=$id"
  echo "  BLOCK: Resource exists in AWS but could not be imported into state."
  echo "  BLOCK: Apply would attempt to recreate this resource — stopping."
  blocked=$((blocked+1))
  rm -f "$import_err"
}

echo "=== Auto-import existing resources ==="

# ── IAM Account Password Policy ─────────────────────
pw_exists=$(python3 -c "import json; print(json.load(open('$DISCOVERY'))['iam']['password_policy_exists'])" 2>/dev/null || echo "false")
if [ "$pw_exists" = "True" ] || [ "$pw_exists" = "true" ]; then
  # Try all known resource names for password policy
  for rname in remediation_password_policy this default; do
    if grep -rEq 'resource\s+"aws_iam_account_password_policy"\s+"'"$rname"'"' "$WORK_DIR"/*.tf 2>/dev/null; then
      import_resource "aws_iam_account_password_policy.$rname" "iam-account-password-policy"
      break
    fi
  done
fi

# ── CloudTrail ───────────────────────────────────────
# aws_cloudtrail import requires the trail ARN, not just the name
trail_arns=$(python3 -c "
import json
d = json.load(open('$DISCOVERY'))
for t in d.get('cloudtrail',{}).get('trails',[]):
    arn = t.get('TrailARN','')
    name = t.get('Name','')
    bucket = t.get('S3BucketName','')
    if arn:
        print(arn + '|' + name + '|' + bucket)
" 2>/dev/null || true)

for trail_info in $trail_arns; do
  trail_arn=$(echo "$trail_info" | cut -d'|' -f1)
  trail_name=$(echo "$trail_info" | cut -d'|' -f2)
  trail_bucket=$(echo "$trail_info" | cut -d'|' -f3)
  [ -z "$trail_arn" ] && continue
  # Find any aws_cloudtrail resource in the .tf files
  for rname in $(grep -rEoh 'resource\s+"aws_cloudtrail"\s+"([^"]+)"' "$WORK_DIR"/*.tf 2>/dev/null | \
                 sed 's/resource\s*"aws_cloudtrail"\s*"//;s/"//g' || true); do
    import_resource "aws_cloudtrail.$rname" "$trail_arn"
  done
done

# ── Config Recorder ──────────────────────────────────
recorder_names=$(python3 -c "
import json
d = json.load(open('$DISCOVERY'))
for r in d.get('config',{}).get('recorders',[]):
    print(r.get('name',''))
" 2>/dev/null || true)

for rec_name in $recorder_names; do
  [ -z "$rec_name" ] && continue
  for rname in $(grep -rEoh 'resource\s+"aws_config_configuration_recorder"\s+"([^"]+)"' "$WORK_DIR"/*.tf 2>/dev/null | \
                 sed 's/resource\s*"aws_config_configuration_recorder"\s*"//;s/"//g' || true); do
    import_resource "aws_config_configuration_recorder.$rname" "$rec_name"
  done
done

# Config Delivery Channel
channel_names=$(python3 -c "
import json
d = json.load(open('$DISCOVERY'))
for c in d.get('config',{}).get('delivery_channels',[]):
    print(c.get('name',''))
" 2>/dev/null || true)

for ch_name in $channel_names; do
  [ -z "$ch_name" ] && continue
  for rname in $(grep -rEoh 'resource\s+"aws_config_delivery_channel"\s+"([^"]+)"' "$WORK_DIR"/*.tf 2>/dev/null | \
                 sed 's/resource\s*"aws_config_delivery_channel"\s*"//;s/"//g' || true); do
    import_resource "aws_config_delivery_channel.$rname" "$ch_name"
  done
done

# ── GuardDuty ────────────────────────────────────────
detector_ids=$(python3 -c "
import json
d = json.load(open('$DISCOVERY'))
for did in d.get('guardduty',{}).get('detector_ids',[]):
    print(did)
" 2>/dev/null || true)

for det_id in $detector_ids; do
  [ -z "$det_id" ] && continue
  for rname in $(grep -rEoh 'resource\s+"aws_guardduty_detector"\s+"([^"]+)"' "$WORK_DIR"/*.tf 2>/dev/null | \
                 sed 's/resource\s*"aws_guardduty_detector"\s*"//;s/"//g' || true); do
    import_resource "aws_guardduty_detector.$rname" "$det_id"
  done
done

# ── SecurityHub ──────────────────────────────────────
sh_enabled=$(python3 -c "import json; print(json.load(open('$DISCOVERY'))['securityhub']['enabled'])" 2>/dev/null || echo "false")
if [ "$sh_enabled" = "True" ] || [ "$sh_enabled" = "true" ]; then
  for rname in $(grep -rEoh 'resource\s+"aws_securityhub_account"\s+"([^"]+)"' "$WORK_DIR"/*.tf 2>/dev/null | \
                 sed 's/resource\s*"aws_securityhub_account"\s*"//;s/"//g' || true); do
    import_resource "aws_securityhub_account.$rname" "$ACCOUNT"
  done
fi

# ── S3 Buckets and sub-resources ─────────────────────
# Determine the target bucket from discovery (same logic as generate_tfvars.py)
target_bucket=$(python3 -c "
import json
d = json.load(open('$DISCOVERY'))
account_id = d.get('account_id','')
state_bucket = f'prowler-terraform-state-{account_id}'
trails = d.get('cloudtrail',{}).get('trails',[])
buckets = d.get('s3',{}).get('buckets',[])
# Primary: CloudTrail log bucket from trail config
ct_bucket = ''
for t in trails:
    b = t.get('S3BucketName','')
    if b:
        ct_bucket = b
        break
if not ct_bucket:
    for b in buckets:
        if 'cloudtrail' in b:
            ct_bucket = b
            break
# Fallback: first non-state bucket
first_bucket = ''
for b in buckets:
    if b != state_bucket:
        first_bucket = b
        break
# Print cloudtrail bucket and first bucket (pipe-separated)
print(f'{ct_bucket}|{first_bucket}')
" 2>/dev/null || echo "|")

ct_target=$(echo "$target_bucket" | cut -d'|' -f1)
s3_target=$(echo "$target_bucket" | cut -d'|' -f2)

# S3 resource types that use bucket name as import ID
S3_SUB_TYPES=(
  "aws_s3_bucket"
  "aws_s3_bucket_server_side_encryption_configuration"
  "aws_s3_bucket_versioning"
  "aws_s3_bucket_public_access_block"
  "aws_s3_bucket_ownership_controls"
  "aws_s3_bucket_policy"
  "aws_s3_bucket_lifecycle_configuration"
)

# Use the CloudTrail bucket as primary target (most remediation files target it)
# Fall back to first non-state bucket
import_bucket="${ct_target:-$s3_target}"

if [ -n "$import_bucket" ]; then
  for s3type in "${S3_SUB_TYPES[@]}"; do
    for rname in $(grep -rEoh "resource\s+\"$s3type\"\s+\"([^\"]+)\"" "$WORK_DIR"/*.tf 2>/dev/null | \
                   sed "s/resource\s*\"$s3type\"\s*\"//;s/\"//g" || true); do
      import_resource "$s3type.$rname" "$import_bucket"
    done
  done
fi

echo "Auto-import done: imported=$imported skipped=$skipped failed=$failed blocked=$blocked"

if [ "$blocked" -gt 0 ]; then
  echo "FATAL: $blocked resource(s) exist in AWS but could not be imported."
  echo "Apply would create duplicates. Fix import IDs or remove conflicting resources."
  exit 1
fi
