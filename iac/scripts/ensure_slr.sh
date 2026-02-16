#!/usr/bin/env bash
# ensure_slr.sh — Service-Linked Role 자동 생성
# apply 전에 필요한 SLR을 미리 생성하여 apply 실패 방지
set -euo pipefail

DISCOVERY="${1:-/tmp/aws_discovery.json}"

SLR_SERVICES=(
  "config.amazonaws.com"
  "guardduty.amazonaws.com"
  "securityhub.amazonaws.com"
  "cloudtrail.amazonaws.com"
  "ssm.amazonaws.com"
  "kms.amazonaws.com"
  "elasticloadbalancing.amazonaws.com"
  "autoscaling.amazonaws.com"
  "ec2.amazonaws.com"
)

echo "=== Ensuring Service-Linked Roles ==="

for svc in "${SLR_SERVICES[@]}"; do
  exists="false"
  if [ -f "$DISCOVERY" ]; then
    exists=$(python3 -c "
import json
d = json.load(open('$DISCOVERY'))
print(str(d.get('service_linked_roles',{}).get('$svc', False)).lower())
" 2>/dev/null || echo "false")
  fi

  if [ "$exists" = "true" ]; then
    echo "  OK: SLR for $svc already exists"
    continue
  fi

  echo "  CREATE: SLR for $svc"
  if aws iam create-service-linked-role --aws-service-name "$svc" 2>&1; then
    echo "  OK: Created SLR for $svc"
  else
    # InvalidInput = already exists (race condition safe)
    if aws iam list-roles --path-prefix "/aws-service-role/$svc/" \
        --query 'Roles[0].RoleName' --output text 2>/dev/null | grep -qv '^None$'; then
      echo "  OK: SLR for $svc already exists (concurrent create)"
    else
      echo "  WARN: Failed to create SLR for $svc (may need manual creation)"
    fi
  fi
done

echo "SLR check complete."
