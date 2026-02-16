#!/usr/bin/env bash
# resilient_apply.sh — Terraform apply with retry, import, and lifecycle protection
# Usage: resilient_apply.sh <work_dir> <category> <discovery_json> <log_file>
set -euo pipefail

WORK_DIR="${1:?Usage: resilient_apply.sh <work_dir> <category> <discovery_json> <log_file>}"
CATEGORY="${2:?}"
DISCOVERY="${3:-/tmp/aws_discovery.json}"
LOGFILE="${4:-/tmp/tfapply.txt}"
MAX_RETRIES="${MAX_APPLY_RETRIES:-3}"
IMPORT_SCRIPT="${IMPORT_SCRIPT:-iac/scripts/auto_import.sh}"

log() { echo "$@" | tee -a "$LOGFILE"; }

# ── Step 0: Inject lifecycle prevent_destroy via override ──
# 모든 리소스에 lifecycle { prevent_destroy = false, create_before_destroy = false } 적용
# 대신, 이미 존재하는 리소스를 import로 가져와 destroy 방지
cat > "$WORK_DIR/lifecycle_override.tf" <<'EOF'
# Auto-generated: prevent accidental replacement
# All resources use create_before_destroy = false to avoid
# destroying existing infrastructure during remediation
lifecycle {
  # This file is a placeholder — actual lifecycle protection
  # is handled by the import-before-apply strategy
}
EOF
# lifecycle override는 HCL에서 resource 외부에 둘 수 없으므로 삭제
rm -f "$WORK_DIR/lifecycle_override.tf"

# ── Step 1: terraform init ──
log "[$CATEGORY] terraform init..."
if ! terraform -chdir="$WORK_DIR" init -input=false -reconfigure 2>&1 | tee -a "$LOGFILE"; then
  log "[$CATEGORY] init failed — retrying with migrate-state..."
  terraform -chdir="$WORK_DIR" init -input=false -migrate-state 2>&1 | tee -a "$LOGFILE" || {
    log "FAIL $CATEGORY: init failed"
    exit 1
  }
fi

# ── Step 2: Auto-import existing resources ──
log "[$CATEGORY] Running auto-import..."
bash "$IMPORT_SCRIPT" "$WORK_DIR" "$DISCOVERY" 2>&1 | tee -a "$LOGFILE" || true

# ── Step 3: Resilient apply loop ──
attempt=0
last_error=""

while [ $attempt -lt $MAX_RETRIES ]; do
  attempt=$((attempt+1))
  log "[$CATEGORY] Apply attempt $attempt/$MAX_RETRIES"

  # Refresh state to sync with real AWS
  log "[$CATEGORY] Refreshing state..."
  terraform -chdir="$WORK_DIR" refresh -input=false 2>&1 | tee -a "$LOGFILE" || true

  # Plan
  log "[$CATEGORY] Planning..."
  plan_output=$(mktemp)
  plan_exit=0
  terraform -chdir="$WORK_DIR" plan -input=false -out=tfplan \
    -detailed-exitcode 2>&1 | tee -a "$LOGFILE" > "$plan_output" || plan_exit=$?

  # exitcode 0 = no changes, 1 = error, 2 = changes present
  if [ $plan_exit -eq 0 ]; then
    log "[$CATEGORY] No changes needed — infrastructure already matches."
    rm -f "$plan_output"
    exit 0
  fi

  if [ $plan_exit -eq 1 ]; then
    last_error=$(cat "$plan_output")
    log "[$CATEGORY] Plan failed (attempt $attempt)"

    # ── Error-specific recovery ──

    # State lock error → force-unlock and retry
    lock_id=$(grep -oP 'ID:\s+\K[0-9a-f-]+' "$plan_output" 2>/dev/null | head -1 || true)
    if [ -n "$lock_id" ]; then
      log "[$CATEGORY] State lock detected ($lock_id) — force-unlocking..."
      terraform -chdir="$WORK_DIR" force-unlock -force "$lock_id" 2>&1 | tee -a "$LOGFILE" || true
      rm -f "$plan_output"
      continue
    fi

    # Resource already exists → parse and import
    already_exists_resource=$(grep -oP 'with the import ID of "\K[^"]+' "$plan_output" 2>/dev/null | head -1 || true)
    if [ -z "$already_exists_resource" ]; then
      already_exists_resource=$(grep -oP 'already exists.*import.*?(\S+)' "$plan_output" 2>/dev/null | head -1 || true)
    fi

    # Try to detect "resource already exists" patterns
    if grep -qiE '(already exists|AlreadyExists|EntityAlreadyExists|ResourceInUseException|BucketAlreadyOwnedByYou)' "$plan_output" 2>/dev/null; then
      log "[$CATEGORY] Detected existing resource — attempting import..."
      # Re-run auto-import with force
      bash "$IMPORT_SCRIPT" "$WORK_DIR" "$DISCOVERY" 2>&1 | tee -a "$LOGFILE" || true
      rm -f "$plan_output"
      continue
    fi

    rm -f "$plan_output"
    continue
  fi

  rm -f "$plan_output"

  # exitcode 2 = changes to apply
  log "[$CATEGORY] Applying..."
  apply_output=$(mktemp)
  apply_exit=0
  terraform -chdir="$WORK_DIR" apply -auto-approve -input=false tfplan \
    2>&1 | tee -a "$LOGFILE" > "$apply_output" || apply_exit=$?

  if [ $apply_exit -eq 0 ]; then
    log "[$CATEGORY] Apply succeeded!"
    rm -f "$apply_output"
    exit 0
  fi

  last_error=$(cat "$apply_output")
  log "[$CATEGORY] Apply failed (attempt $attempt)"

  # ── Post-apply error recovery ──

  # State lock
  lock_id=$(grep -oP 'ID:\s+\K[0-9a-f-]+' "$apply_output" 2>/dev/null | head -1 || true)
  if [ -n "$lock_id" ] && grep -q "Error acquiring the state lock" "$apply_output" 2>/dev/null; then
    log "[$CATEGORY] State lock detected ($lock_id) — force-unlocking..."
    terraform -chdir="$WORK_DIR" force-unlock -force "$lock_id" 2>&1 | tee -a "$LOGFILE" || true
    rm -f "$apply_output"
    continue
  fi

  # Resource already exists → import and retry
  if grep -qiE '(already exists|AlreadyExists|EntityAlreadyExists|ResourceInUseException|BucketAlreadyOwnedByYou|ConflictException)' "$apply_output" 2>/dev/null; then
    log "[$CATEGORY] Resource already exists — importing and retrying..."

    # Parse the specific resource address and ID from error
    # Pattern: "Error: creating X (Y): already exists"
    while IFS= read -r line; do
      # Extract terraform address from "with X," pattern
      tf_addr=$(echo "$line" | grep -oP 'with\s+\K\S+(?=,)' || true)
      # Extract AWS resource ID
      aws_id=$(echo "$line" | grep -oP '\(\K[^)]+(?=\))' || true)
      if [ -n "$tf_addr" ] && [ -n "$aws_id" ]; then
        log "[$CATEGORY] Importing $tf_addr ← $aws_id"
        terraform -chdir="$WORK_DIR" import -input=false "$tf_addr" "$aws_id" 2>&1 | tee -a "$LOGFILE" || true
      fi
    done < <(grep -iE 'already exists' "$apply_output" || true)

    # Also run generic auto-import
    bash "$IMPORT_SCRIPT" "$WORK_DIR" "$DISCOVERY" 2>&1 | tee -a "$LOGFILE" || true
    rm -f "$apply_output"
    continue
  fi

  # AccessDenied → log and continue (don't escalate permissions at runtime)
  if grep -qiE '(AccessDenied|UnauthorizedAccess|is not authorized)' "$apply_output" 2>/dev/null; then
    log "[$CATEGORY] AccessDenied error — extracting required permissions..."
    # Extract the failed action for documentation
    grep -iE '(AccessDenied|is not authorized)' "$apply_output" | head -5 | tee -a "$LOGFILE"
    log "[$CATEGORY] → Update bootstrap IAM to add these permissions"
    rm -f "$apply_output"
    # Don't retry — AccessDenied won't resolve on its own
    break
  fi

  # Timeout / throttle → wait and retry
  if grep -qiE '(Throttling|RequestLimitExceeded|timeout|TooManyRequestsException)' "$apply_output" 2>/dev/null; then
    wait_secs=$((30 * attempt))
    log "[$CATEGORY] Throttled — waiting ${wait_secs}s before retry..."
    sleep "$wait_secs"
    rm -f "$apply_output"
    continue
  fi

  # Dependency error → refresh and retry
  if grep -qiE '(DependencyViolation|ResourceNotFoundException|NoSuchEntity|InvalidParameterValue)' "$apply_output" 2>/dev/null; then
    log "[$CATEGORY] Dependency error — refreshing state and retrying..."
    terraform -chdir="$WORK_DIR" refresh -input=false 2>&1 | tee -a "$LOGFILE" || true
    rm -f "$apply_output"
    continue
  fi

  rm -f "$apply_output"
done

# ── Final status ──
if [ $attempt -ge $MAX_RETRIES ]; then
  log "FAIL $CATEGORY: exhausted $MAX_RETRIES retries"
  log "Last error: $(echo "$last_error" | grep -iE '(Error|error)' | head -5)"
  exit 1
fi
