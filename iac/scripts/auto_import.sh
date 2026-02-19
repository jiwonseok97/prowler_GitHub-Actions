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
  local rname_full=$(echo "$addr" | cut -d'.' -f2-)
  local rname=$(echo "$rname_full" | sed 's/\[.*$//')
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
  [ -z "$trail_arn" ] && continue
  [ -z "$trail_name" ] && continue

  # Preferred path: for_each resource address by trail name.
  if grep -rEq 'resource\s+"aws_cloudtrail"\s+"remediation_existing"' "$WORK_DIR"/*.tf 2>/dev/null; then
    import_resource "aws_cloudtrail.remediation_existing[\"$trail_name\"]" "$trail_arn"
    continue
  fi

  # Legacy path: single-resource cloudtrail snippet.
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
# Determine CloudTrail buckets and fallback target bucket from discovery.
target_bucket=$(python3 -c "
import json
d = json.load(open('$DISCOVERY'))
account_id = d.get('account_id','')
state_bucket = f'prowler-terraform-state-{account_id}'
trails = d.get('cloudtrail',{}).get('trails',[])
buckets = d.get('s3',{}).get('buckets',[])
# Primary: CloudTrail log bucket from trail config
ct_bucket = ''
ct_buckets = []
for t in trails:
    b = t.get('S3BucketName','')
    if b:
        if b not in ct_buckets:
            ct_buckets.append(b)
        if not ct_bucket:
            ct_bucket = b
if not ct_bucket:
    for b in buckets:
        if 'cloudtrail' in b:
            ct_bucket = b
            if b not in ct_buckets:
                ct_buckets.append(b)
            break
# Fallback: first non-state bucket
first_bucket = ''
for b in buckets:
    if b != state_bucket:
        first_bucket = b
        break
# Print cloudtrail primary bucket, first non-state bucket, and all ct buckets.
print(f'{ct_bucket}|{first_bucket}|{",".join(ct_buckets)}')
" 2>/dev/null || echo "|")

ct_target=$(echo "$target_bucket" | cut -d'|' -f1)
s3_target=$(echo "$target_bucket" | cut -d'|' -f2)
ct_targets_csv=$(echo "$target_bucket" | cut -d'|' -f3)

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
IFS=',' read -r -a ct_targets <<< "${ct_targets_csv:-}"

if [ -n "$import_bucket" ] || [ "${#ct_targets[@]}" -gt 0 ]; then
  for s3type in "${S3_SUB_TYPES[@]}"; do
    for rname in $(grep -rEoh "resource\s+\"$s3type\"\s+\"([^\"]+)\"" "$WORK_DIR"/*.tf 2>/dev/null | \
                   sed "s/resource\s*\"$s3type\"\s*\"//;s/\"//g" || true); do
      if grep -A20 -E "resource\s+\"$s3type\"\s+\"$rname\"" "$WORK_DIR"/*.tf 2>/dev/null | grep -q "for_each"; then
        if [ "${#ct_targets[@]}" -gt 0 ]; then
          for bucket in "${ct_targets[@]}"; do
            [ -z "$bucket" ] && continue
            import_resource "$s3type.$rname[\"$bucket\"]" "$bucket"
          done
        elif [ -n "$import_bucket" ]; then
          import_resource "$s3type.$rname[\"$import_bucket\"]" "$import_bucket"
        fi
      elif [ -n "$import_bucket" ]; then
        import_resource "$s3type.$rname" "$import_bucket"
      fi
    done
  done
fi

# ── SNS Topics ────────────────────────────────────
# Import existing SNS topics that match remediation resource names
for rname in $(grep -rEoh 'resource\s+"aws_sns_topic"\s+"([^"]+)"' "$WORK_DIR"/*.tf 2>/dev/null | \
               sed 's/resource\s*"aws_sns_topic"\s*"//;s/"//g' || true); do
  # Derive topic name from resource name (convention: resource name = topic name with underscores→hyphens)
  topic_name=$(echo "$rname" | tr '_' '-')
  topic_arn="arn:aws:sns:${REGION}:${ACCOUNT}:${topic_name}"
  import_resource "aws_sns_topic.$rname" "$topic_arn"
done

# ── CloudWatch Log Groups ──────────────────────────
# Import if a log group with the same name already exists in AWS
for rname in $(grep -rEoh 'resource\s+"aws_cloudwatch_log_group"\s+"([^"]+)"' "$WORK_DIR"/*.tf 2>/dev/null | \
               sed 's/resource\s*"aws_cloudwatch_log_group"\s*"//;s/"//g' || true); do
  lg_name=$(grep -A10 "resource\s*\"aws_cloudwatch_log_group\"\s*\"$rname\"" "$WORK_DIR"/*.tf 2>/dev/null | \
    grep -oP 'name\s*=\s*"\K[^"]+' | head -1 || true)
  [ -z "$lg_name" ] && continue
  exists=$(python3 -c "
import json
d = json.load(open('$DISCOVERY'))
groups = d.get('cloudwatch', {}).get('log_groups', [])
print('true' if '$lg_name' in groups else 'false')
" 2>/dev/null || echo "false")
  if [ "$exists" = "true" ]; then
    # count-based resource → address includes [0]
    import_resource "aws_cloudwatch_log_group.${rname}[0]" "$lg_name" 2>/dev/null || \
    import_resource "aws_cloudwatch_log_group.${rname}" "$lg_name" 2>/dev/null || true
  fi
done

# ── IAM Roles (remediation-* prefix only) ──────────
for rname in $(grep -rEoh 'resource\s+"aws_iam_role"\s+"([^"]+)"' "$WORK_DIR"/*.tf 2>/dev/null | \
               sed 's/resource\s*"aws_iam_role"\s*"//;s/"//g' || true); do
  role_name=$(grep -A10 "resource\s*\"aws_iam_role\"\s*\"$rname\"" "$WORK_DIR"/*.tf 2>/dev/null | \
    grep -oP 'name\s*=\s*"\K[^"]+' | head -1 || true)
  [[ "$role_name" == remediation-* ]] || continue
  # Try import; if role doesn't exist in AWS, import fails safely (resource will be created)
  import_resource "aws_iam_role.${rname}[0]" "$role_name" 2>/dev/null || \
  import_resource "aws_iam_role.${rname}" "$role_name" 2>/dev/null || true
done

# ── CloudWatch Log Metric Filters ──────────────────
# Import existing metric filters that match resources declared in .tf files
for rname in $(grep -rEoh 'resource\s+"aws_cloudwatch_log_metric_filter"\s+"([^"]+)"' "$WORK_DIR"/*.tf 2>/dev/null | \
               sed 's/resource\s*"aws_cloudwatch_log_metric_filter"\s*"//;s/"//g' || true); do
  filter_name=$(grep -A5 "resource\s*\"aws_cloudwatch_log_metric_filter\"\s*\"$rname\"" "$WORK_DIR"/*.tf 2>/dev/null | \
    grep -oP 'name\s*=\s*"\K[^"]+' | head -1 || true)
  if [ -n "$filter_name" ]; then
    # Try discovery log group first, then fallback to /cloudtrail/remediation
    lg_name=$(python3 -c "
import json
d = json.load(open('$DISCOVERY'))
trails = d.get('cloudtrail',{}).get('trails',[])
for t in trails:
    arn = t.get('CloudWatchLogsLogGroupArn','')
    if arn:
        parts = arn.split(':')
        if len(parts) >= 7:
            print(parts[6])
            break
" 2>/dev/null || true)
    [ -z "$lg_name" ] && lg_name="/cloudtrail/remediation"
    import_resource "aws_cloudwatch_log_metric_filter.$rname" "${lg_name}:${filter_name}"
  fi
done

# ── S3 for_each resources ───────────────────────────
# Handle resources using for_each = toset(var.s3_bucket_names)
if grep -rEq 'for_each\s*=.*s3_bucket_names|for_each\s*=\s*local\.buckets' "$WORK_DIR"/*.tf 2>/dev/null; then
  all_s3_buckets=$(python3 -c "
import json
d = json.load(open('$DISCOVERY'))
account = d.get('account_id', '')
state_bucket = f'prowler-terraform-state-{account}'
for b in d.get('s3', {}).get('buckets', []):
    if b != state_bucket:
        print(b)
" 2>/dev/null || true)

  for_each_s3_types=(
    "aws_s3_bucket_server_side_encryption_configuration"
    "aws_s3_bucket_versioning"
    "aws_s3_bucket_public_access_block"
    "aws_s3_bucket_policy"
    "aws_s3_bucket_ownership_controls"
  )

  for bucket in $all_s3_buckets; do
    for s3type in "${for_each_s3_types[@]}"; do
      rname="remediation_s3"
      if grep -rEq "resource\s+\"$s3type\"\s+\"$rname\"" "$WORK_DIR"/*.tf 2>/dev/null; then
        addr="${s3type}.${rname}[\"${bucket}\"]"
        if ! terraform -chdir="$WORK_DIR" state show "${addr}" >/dev/null 2>&1; then
          echo "  IMPORT ${addr} ← ${bucket}"
          terraform -chdir="$WORK_DIR" import -input=false "${addr}" "${bucket}" 2>&1 || \
            echo "  WARN: import may have failed for ${addr}"
        else
          echo "  SKIP import ${addr} (already in state)"
        fi
      fi
    done
  done
fi

echo "Auto-import done: imported=$imported skipped=$skipped failed=$failed blocked=$blocked"

if [ "$blocked" -gt 0 ]; then
  echo "FATAL: $blocked resource(s) exist in AWS but could not be imported."
  echo "Apply would create duplicates. Fix import IDs or remove conflicting resources."
  exit 1
fi
