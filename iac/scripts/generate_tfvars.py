#!/usr/bin/env python3
"""generate_tfvars.py - Populate variable values from AWS discovery data.

Reads preflight_discovery.sh output and writes a discovery.auto.tfvars file
into the Terraform work directory. This replaces default="" with real values
so that count guards evaluate to resource creation paths.

Usage: python3 generate_tfvars.py <discovery_json> <work_dir> <category> [manifest_json]
"""
import json
import os
import re
import sys


def load_discovery(path: str) -> dict:
    try:
        with open(path, "r", encoding="utf-8-sig") as f:
            return json.load(f)
    except (FileNotFoundError, json.JSONDecodeError) as e:
        print(f"WARN: Cannot load discovery: {e}")
        return {}


def find_referenced_vars(work_dir: str) -> set[str]:
    """Scan .tf files in work_dir for var.xxx references."""
    refs = set()
    for name in os.listdir(work_dir):
        if not name.endswith(".tf"):
            continue
        try:
            text = open(os.path.join(work_dir, name), encoding="utf-8").read()
        except OSError:
            continue
        for m in re.finditer(r"var\.([A-Za-z_][A-Za-z0-9_]*)", text):
            refs.add(m.group(1))
    return refs


def find_declared_vars(work_dir: str) -> set[str]:
    """Scan .tf files in work_dir for variable declarations."""
    declared = set()
    for name in os.listdir(work_dir):
        if not name.endswith(".tf"):
            continue
        try:
            text = open(os.path.join(work_dir, name), encoding="utf-8").read()
        except OSError:
            continue
        for m in re.finditer(r'variable\s+"([A-Za-z_][A-Za-z0-9_]*)"', text):
            declared.add(m.group(1))
    return declared


def _trail_name_from_arn(arn: str) -> str:
    if not arn:
        return ""
    m = re.search(r":trail/([^:/]+)$", arn)
    return m.group(1) if m else ""


def _bucket_name_from_arn(arn: str) -> str:
    if not arn:
        return ""
    m = re.search(r"^arn:aws:s3:::([^/]+)", arn)
    return m.group(1) if m else ""


def _log_group_name_from_arn(arn: str) -> str:
    if not arn:
        return ""
    m = re.search(r":log-group:([^:*]+)", arn)
    return m.group(1) if m else ""


def load_manifest_targets(path: str, category: str) -> dict[str, list[str]]:
    targets = {"trail_names": [], "bucket_names": [], "log_group_names": []}
    if not path:
        return targets
    try:
        with open(path, "r", encoding="utf-8-sig") as f:
            items = json.load(f)
    except (FileNotFoundError, json.JSONDecodeError, OSError) as e:
        print(f"WARN: Cannot load manifest targets: {e}")
        return targets

    for item in items:
        if str(item.get("category", "")).strip() != category:
            continue
        if str(item.get("validation_status", "ok")).strip().lower() == "excluded":
            continue

        check_id = str(item.get("check_id", "")).strip()
        resource_name = str(item.get("resource_name", "")).strip()
        resource_arn = str(item.get("resource_arn", "")).strip()
        resource_uid = str(item.get("resource_uid", "")).strip()

        if category == "cloudtrail" and check_id.startswith("cloudtrail_"):
            trail_name = resource_name or _trail_name_from_arn(resource_arn) or _trail_name_from_arn(resource_uid)
            if trail_name:
                targets["trail_names"].append(trail_name)

        if category == "s3" and check_id.startswith("s3_"):
            bucket = resource_name or _bucket_name_from_arn(resource_arn) or _bucket_name_from_arn(resource_uid)
            if bucket:
                targets["bucket_names"].append(bucket)

        if category == "cloudwatch" and check_id.startswith("cloudwatch_"):
            log_group = resource_name or _log_group_name_from_arn(resource_arn) or _log_group_name_from_arn(resource_uid)
            if log_group:
                targets["log_group_names"].append(log_group)

    for key, vals in targets.items():
        seen = set()
        deduped = []
        for v in vals:
            if v and v not in seen:
                seen.add(v)
                deduped.append(v)
        targets[key] = deduped

    return targets


def _cloudtrail_noncompliance_score(trail: dict) -> int:
    score = 0
    if not trail.get("LogFileValidationEnabled"):
        score += 1
    if not trail.get("IsMultiRegionTrail"):
        score += 1
    if not str(trail.get("KmsKeyId", "")).strip():
        score += 1
    if not str(trail.get("CloudWatchLogsLogGroupArn", "")).strip():
        score += 1
    return score


def generate(
    discovery: dict,
    work_dir: str,
    category: str,
    manifest_targets: dict[str, list[str]] | None = None,
) -> dict[str, str]:
    """Return {variable_name: hcl_value} for the given category."""
    vals: dict[str, str] = {}
    refs = find_referenced_vars(work_dir)
    manifest_targets = manifest_targets or {"trail_names": [], "bucket_names": [], "log_group_names": []}

    buckets = discovery.get("s3", {}).get("buckets", [])
    trails = discovery.get("cloudtrail", {}).get("trails", [])
    aliases = discovery.get("kms", {}).get("aliases", [])
    account_id = discovery.get("account_id", "")
    state_bucket = f"prowler-terraform-state-{account_id}"

    selected_trail = None
    preferred_trails = set(manifest_targets.get("trail_names", []))
    if preferred_trails:
        candidates = []
        for trail in trails:
            name = str(trail.get("Name", "")).strip()
            if name and name in preferred_trails:
                candidates.append(trail)
        if candidates:
            selected_trail = sorted(
                candidates,
                key=lambda t: (
                    -_cloudtrail_noncompliance_score(t),
                    str(t.get("Name", "")),
                ),
            )[0]

    # Find the primary CloudTrail log bucket.
    ct_bucket = ""
    candidate_trails = [selected_trail] if selected_trail else trails
    for trail in candidate_trails:
        if not trail:
            continue
        bucket = trail.get("S3BucketName", "")
        if bucket:
            ct_bucket = bucket
            break
    if not ct_bucket:
        for bucket in buckets:
            if "cloudtrail" in bucket and not bucket.endswith("-logs"):
                ct_bucket = bucket
                break

    # Find the access-logging target bucket (usually ends with -logs).
    log_bucket = ""
    for bucket in buckets:
        if bucket.endswith("-logs"):
            log_bucket = bucket
            break

    # Prefer customer-managed KMS key; fallback to AWS-managed S3 key alias.
    kms_key_id = ""
    for alias in aliases:
        kid = alias.get("TargetKeyId")
        alias_name = alias.get("AliasName", "")
        if kid and alias_name and not alias_name.startswith("alias/aws/"):
            kms_key_id = kid
            break
    if not kms_key_id:
        for alias in aliases:
            kid = alias.get("TargetKeyId")
            if kid and alias.get("AliasName", "") == "alias/aws/s3":
                kms_key_id = kid
                break

    if category == "cloudtrail":
        if "s3_bucket_name" in refs and ct_bucket:
            vals["s3_bucket_name"] = ct_bucket
        if "s3_bucket_arn" in refs and ct_bucket:
            vals["s3_bucket_arn"] = f"arn:aws:s3:::{ct_bucket}"
        if "cloudtrail_name" in refs:
            if selected_trail:
                vals["cloudtrail_name"] = selected_trail.get("Name", "")
            elif trails:
                vals["cloudtrail_name"] = trails[0].get("Name", "")
        if "log_bucket_name" in refs and log_bucket:
            vals["log_bucket_name"] = log_bucket
        if "kms_key_id" in refs and kms_key_id:
            vals["kms_key_id"] = kms_key_id

    elif category == "s3":
        preferred_buckets = [b for b in manifest_targets.get("bucket_names", []) if b]
        all_buckets = [b for b in buckets if b != state_bucket]
        if preferred_buckets and len(preferred_buckets) > 1:
            preferred_set = set(preferred_buckets)
            selected_buckets = [b for b in all_buckets if b in preferred_set]
        else:
            selected_buckets = all_buckets

        if "s3_bucket_names" in refs and selected_buckets:
            vals["s3_bucket_names"] = selected_buckets
        if "s3_bucket_name" in refs and "s3_bucket_names" not in refs and selected_buckets:
            vals["s3_bucket_name"] = selected_buckets[0]
        if "s3_bucket_arn" in refs and "s3_bucket_name" in vals:
            vals["s3_bucket_arn"] = f"arn:aws:s3:::{vals['s3_bucket_name']}"
        if "s3_logging_bucket_name" in refs and log_bucket:
            vals["s3_logging_bucket_name"] = log_bucket
        if "log_bucket_name" in refs and log_bucket:
            vals["log_bucket_name"] = log_bucket
        if "kms_key_id" in refs and kms_key_id:
            vals["kms_key_id"] = kms_key_id

    elif category == "kms":
        if "kms_key_id" in refs:
            for alias in aliases:
                kid = alias.get("TargetKeyId")
                if kid and not alias.get("AliasName", "").startswith("alias/aws/"):
                    vals["kms_key_id"] = kid
                    break

    elif category == "cloudwatch":
        log_groups = discovery.get("cloudwatch", {}).get("log_groups", [])
        ct_log_group = ""

        preferred_log_groups = [n for n in manifest_targets.get("log_group_names", []) if n]
        if preferred_log_groups:
            ct_log_group = preferred_log_groups[0]

        candidate_trails = [selected_trail] if selected_trail else trails
        for trail in candidate_trails:
            if not trail:
                continue
            lg_arn = trail.get("CloudWatchLogsLogGroupArn", "")
            if lg_arn:
                parts = lg_arn.split(":")
                if len(parts) >= 7:
                    ct_log_group = parts[6]
                    break

        if not ct_log_group:
            for lg in log_groups:
                name = lg if isinstance(lg, str) else lg.get("logGroupName", "")
                if "cloudtrail" in name.lower():
                    ct_log_group = name
                    break

        if "cloudwatch_log_group_name" in refs and ct_log_group:
            vals["cloudwatch_log_group_name"] = ct_log_group

    elif category == "network-ec2-vpc":
        vpcs = discovery.get("vpc", {}).get("vpcs", [])
        subnets = discovery.get("vpc", {}).get("subnets", [])
        if "vpc_id" in refs and vpcs:
            vals["vpc_id"] = vpcs[0] if isinstance(vpcs[0], str) else vpcs[0].get("VpcId", "")
        if "firewall_subnet_id" in refs and subnets:
            vals["firewall_subnet_id"] = subnets[0] if isinstance(subnets[0], str) else subnets[0].get("SubnetId", "")

    elif category == "org-account":
        org = discovery.get("organizations")
        if org and isinstance(org, dict) and org.get("Id"):
            if "organizations_enable" in refs:
                vals["organizations_enable"] = "true"

    return vals


def write_tfvars(vals: dict, work_dir: str) -> None:
    if not vals:
        return
    path = os.path.join(work_dir, "discovery.auto.tfvars")
    lines = []
    for key, value in sorted(vals.items()):
        if isinstance(value, list):
            items = ", ".join(f'"{str(x)}"' for x in value)
            lines.append(f"{key} = [{items}]")
        else:
            escaped = str(value).replace("\\", "\\\\").replace('"', '\\"')
            lines.append(f'{key} = "{escaped}"')
    with open(path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")
    print(f"  Generated {path}: {list(vals.keys())}")


def prune_auto_tfvars(work_dir: str) -> None:
    """Remove undeclared keys from *.auto.tfvars files in work_dir."""
    declared = find_declared_vars(work_dir)
    if not declared:
        return

    for name in os.listdir(work_dir):
        if not name.endswith(".auto.tfvars"):
            continue
        path = os.path.join(work_dir, name)
        try:
            lines = open(path, "r", encoding="utf-8").read().splitlines()
        except OSError:
            continue

        kept: list[str] = []
        removed: list[str] = []
        for line in lines:
            stripped = line.strip()
            if not stripped or stripped.startswith("#"):
                kept.append(line)
                continue
            m = re.match(r"^([A-Za-z_][A-Za-z0-9_]*)\s*=", stripped)
            if not m:
                kept.append(line)
                continue
            key = m.group(1)
            if key in declared:
                kept.append(line)
            else:
                removed.append(key)

        if removed:
            with open(path, "w", encoding="utf-8") as f:
                f.write("\n".join(kept).rstrip() + "\n")
            print(f"  Pruned {name}: removed undeclared keys {sorted(set(removed))}")


def main():
    if len(sys.argv) < 4:
        print("Usage: generate_tfvars.py <discovery_json> <work_dir> <category> [manifest_json]")
        sys.exit(1)

    discovery_path = sys.argv[1]
    work_dir = sys.argv[2]
    category = sys.argv[3]
    manifest_path = sys.argv[4] if len(sys.argv) >= 5 else ""

    discovery = load_discovery(discovery_path)
    if not discovery:
        return

    manifest_targets = load_manifest_targets(manifest_path, category) if manifest_path else None
    vals = generate(discovery, work_dir, category, manifest_targets=manifest_targets)
    write_tfvars(vals, work_dir)
    prune_auto_tfvars(work_dir)


if __name__ == "__main__":
    main()
