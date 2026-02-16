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
  if ! grep -rq "$(echo "$addr" | sed 's/\./\\./g')" "$WORK_DIR"/*.tf 2>/dev/null; then
    # addr 형태 확인: resource type + name
    local rtype=$(echo "$addr" | cut -d'.' -f1)
    local rname=$(echo "$addr" | cut -d'.' -f2)
    if ! grep -rEq "resource\s+\"$rtype\"\s+\"$rname\"" "$WORK_DIR"/*.tf 2>/dev/null; then
      return 0
    fi
  fi

  echo "  IMPORT $addr ← $id"
  if terraform -chdir="$WORK_DIR" import -input=false "$addr" "$id" 2>&1; then
    imported=$((imported+1))
  else
    echo "  WARN: import failed for $addr (non-fatal)"
  fi
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
trail_names=$(python3 -c "
import json
d = json.load(open('$DISCOVERY'))
for t in d.get('cloudtrail',{}).get('trails',[]):
    print(t.get('Name',''))
" 2>/dev/null || true)

for trail_name in $trail_names; do
  [ -z "$trail_name" ] && continue
  # Find any aws_cloudtrail resource referencing this trail
  for rname in $(grep -rEoh 'resource\s+"aws_cloudtrail"\s+"([^"]+)"' "$WORK_DIR"/*.tf 2>/dev/null | \
                 sed 's/resource\s*"aws_cloudtrail"\s*"//;s/"//g' || true); do
    import_resource "aws_cloudtrail.$rname" "$trail_name"
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

echo "Auto-import done: imported=$imported skipped=$skipped"
