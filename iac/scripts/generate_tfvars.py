#!/usr/bin/env python3
"""generate_tfvars.py — Populate variable values from AWS discovery data.

Reads preflight_discovery.sh output and writes a discovery.auto.tfvars file
into the Terraform work directory. This replaces default="" with real values
so that count guards (e.g. count = var.s3_bucket_name != "" ? 1 : 0) evaluate
to count=1 instead of count=0.

Usage: python3 generate_tfvars.py <discovery_json> <work_dir> <category>
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


def generate(discovery: dict, work_dir: str, category: str) -> dict[str, str]:
    """Return {variable_name: hcl_value} for the given category."""
    vals: dict[str, str] = {}
    refs = find_referenced_vars(work_dir)

    buckets = discovery.get("s3", {}).get("buckets", [])
    trails = discovery.get("cloudtrail", {}).get("trails", [])
    account_id = discovery.get("account_id", "")
    state_bucket = f"prowler-terraform-state-{account_id}"

    # Find the primary CloudTrail log bucket
    ct_bucket = ""
    for t in trails:
        b = t.get("S3BucketName", "")
        if b:
            ct_bucket = b
            break
    if not ct_bucket:
        for b in buckets:
            if "cloudtrail" in b and not b.endswith("-logs"):
                ct_bucket = b
                break

    # Find the access-logging target bucket (usually ends with -logs)
    log_bucket = ""
    for b in buckets:
        if b.endswith("-logs"):
            log_bucket = b
            break

    if category == "cloudtrail":
        # CloudTrail .tf files use var.s3_bucket_name for the trail's S3 bucket
        if "s3_bucket_name" in refs and ct_bucket:
            vals["s3_bucket_name"] = ct_bucket
        if "s3_bucket_arn" in refs and ct_bucket:
            vals["s3_bucket_arn"] = f"arn:aws:s3:::{ct_bucket}"
        # Trail name
        if "cloudtrail_name" in refs and trails:
            vals["cloudtrail_name"] = trails[0].get("Name", "")
        # Log bucket for access logging
        if "log_bucket_name" in refs and log_bucket:
            vals["log_bucket_name"] = log_bucket

    elif category == "s3":
        # S3 .tf files use var.s3_bucket_name — provide the first non-state bucket
        if "s3_bucket_name" in refs:
            for b in buckets:
                if b != state_bucket:
                    vals["s3_bucket_name"] = b
                    break
        if "s3_bucket_arn" in refs and "s3_bucket_name" in vals:
            vals["s3_bucket_arn"] = f"arn:aws:s3:::{vals['s3_bucket_name']}"
        if "log_bucket_name" in refs and log_bucket:
            vals["log_bucket_name"] = log_bucket

    elif category == "kms":
        # KMS files may reference key IDs
        aliases = discovery.get("kms", {}).get("aliases", [])
        if "kms_key_id" in refs:
            for a in aliases:
                kid = a.get("TargetKeyId")
                if kid and not a.get("AliasName", "").startswith("alias/aws/"):
                    vals["kms_key_id"] = kid
                    break

    elif category == "cloudwatch":
        # CloudWatch CIS filters need the CloudTrail log group name
        log_groups = discovery.get("cloudwatch", {}).get("log_groups", [])
        ct_log_group = ""
        # Find the CloudTrail-linked log group
        for t in trails:
            lg = t.get("CloudWatchLogsLogGroupArn", "")
            if lg:
                # ARN format: arn:aws:logs:region:account:log-group:NAME:*
                parts = lg.split(":")
                if len(parts) >= 7:
                    ct_log_group = parts[6]
                    break
        if not ct_log_group:
            # Fallback: look for log groups with "cloudtrail" in name
            for lg in log_groups:
                name = lg if isinstance(lg, str) else lg.get("logGroupName", "")
                if "cloudtrail" in name.lower():
                    ct_log_group = name
                    break
        if "cloudwatch_log_group_name" in refs and ct_log_group:
            vals["cloudwatch_log_group_name"] = ct_log_group

    elif category == "network-ec2-vpc":
        # VPC-related variables
        vpcs = discovery.get("vpc", {}).get("vpcs", [])
        subnets = discovery.get("vpc", {}).get("subnets", [])
        if "vpc_id" in refs and vpcs:
            vals["vpc_id"] = vpcs[0] if isinstance(vpcs[0], str) else vpcs[0].get("VpcId", "")
        if "firewall_subnet_id" in refs and subnets:
            vals["firewall_subnet_id"] = subnets[0] if isinstance(subnets[0], str) else subnets[0].get("SubnetId", "")

    elif category == "org-account":
        # Organizations-related variables
        org = discovery.get("organizations")
        if org and isinstance(org, dict) and org.get("Id"):
            if "organizations_enable" in refs:
                vals["organizations_enable"] = "true"

    return vals


def write_tfvars(vals: dict[str, str], work_dir: str) -> None:
    if not vals:
        return
    path = os.path.join(work_dir, "discovery.auto.tfvars")
    lines = []
    for k, v in sorted(vals.items()):
        # HCL string quoting
        escaped = v.replace("\\", "\\\\").replace('"', '\\"')
        lines.append(f'{k} = "{escaped}"')
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
        print("Usage: generate_tfvars.py <discovery_json> <work_dir> <category>")
        sys.exit(1)

    discovery_path = sys.argv[1]
    work_dir = sys.argv[2]
    category = sys.argv[3]

    discovery = load_discovery(discovery_path)
    if not discovery:
        return

    vals = generate(discovery, work_dir, category)
    write_tfvars(vals, work_dir)
    prune_auto_tfvars(work_dir)


if __name__ == "__main__":
    main()
