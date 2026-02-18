#!/usr/bin/env python3
"""inject_lifecycle.py — Inject lifecycle blocks into known-safe resource blocks.

Only injects lifecycle blocks into explicitly allowlisted resource types:
  - SAFE_TAGGABLE_TYPES: get ignore_changes = [tags, tags_all]
  - SINGLETON_TYPES: get prevent_destroy = true (and tags if also taggable)
  - Everything else: no lifecycle block injected (avoids terraform validate failures
    on sub-resources that don't support tags or lifecycle at all)

Blocked patterns (never injected):
  - Types in BLOCKED_TYPES
  - Types ending with: _rule, _attachment, _association, _binding

Usage: python3 inject_lifecycle.py <directory>
"""
import re
import sys
import pathlib
import glob

# Singleton resource types: exactly one per account/region, always update-in-place.
# These get prevent_destroy = true.
SINGLETON_TYPES = frozenset({
    "aws_iam_account_password_policy",
    "aws_securityhub_account",
    "aws_guardduty_detector",
    "aws_config_configuration_recorder",
    "aws_config_delivery_channel",
    "aws_config_configuration_recorder_status",
})

# Taggable resource types — only these get ignore_changes = [tags, tags_all].
# Must be the actual top-level resource (not sub-resource configs).
SAFE_TAGGABLE_TYPES = frozenset({
    # S3 top-level bucket (sub-resources like versioning, policy do NOT support tags)
    "aws_s3_bucket",
    # KMS key (not key policy, not alias)
    "aws_kms_key",
    # CloudWatch
    "aws_cloudwatch_log_group",
    "aws_cloudwatch_metric_alarm",
    # CloudTrail
    "aws_cloudtrail",
    # SNS topic (not topic policy)
    "aws_sns_topic",
    # IAM named resources (not attachments)
    "aws_iam_role",
    "aws_iam_policy",
    "aws_iam_user",
    "aws_iam_group",
    # Network / VPC top-level resources
    "aws_vpc",
    "aws_subnet",
    "aws_security_group",
    "aws_network_acl",
    "aws_internet_gateway",
    "aws_route_table",
    "aws_flow_log",
    "aws_vpc_endpoint",
    # Inspector / Security Hub / GuardDuty (top-level, no prevent_destroy needed)
    "aws_inspector2_enabler",
    # Config service (top-level)
    "aws_config_configuration_aggregator",
    # EKS / EC2
    "aws_eks_cluster",
    "aws_instance",
    "aws_ebs_volume",
    "aws_eip",
    # Lambda
    "aws_lambda_function",
    # RDS
    "aws_db_instance",
    "aws_db_subnet_group",
    # ELB
    "aws_lb",
    "aws_lb_target_group",
    # ECR
    "aws_ecr_repository",
})

# Resource types that must never receive a lifecycle block.
BLOCKED_TYPES = frozenset({
    # Network sub-resources (no tags, no lifecycle support)
    "aws_network_acl_rule",
    "aws_route",
    "aws_route_table_association",
    "aws_subnet_cidr_reservation",
    # Attachment/association resources (no tags, stateless link)
    "aws_network_interface_sg_attachment",
    "aws_iam_role_policy_attachment",
    "aws_iam_user_policy_attachment",
    "aws_iam_group_policy_attachment",
    "aws_iam_policy_attachment",
    "aws_iam_role_policy",          # inline policy
    "aws_security_group_rule",      # legacy rule resource
    # S3 sub-resource configs (no tags)
    "aws_s3_bucket_server_side_encryption_configuration",
    "aws_s3_bucket_versioning",
    "aws_s3_bucket_public_access_block",
    "aws_s3_bucket_ownership_controls",
    "aws_s3_bucket_policy",
    "aws_s3_bucket_lifecycle_configuration",
    "aws_s3_bucket_logging",
    "aws_s3_bucket_acl",
    "aws_s3_bucket_cors_configuration",
    "aws_s3_bucket_website_configuration",
    # KMS sub-resources
    "aws_kms_key_policy",
    "aws_kms_alias",
    "aws_kms_grant",
    # CloudWatch sub-resources
    "aws_cloudwatch_log_metric_filter",
    "aws_cloudwatch_log_resource_policy",
    # SNS sub-resources
    "aws_sns_topic_policy",
    "aws_sns_topic_subscription",
    # Config sub-resources
    "aws_config_configuration_recorder_status",
    "aws_config_delivery_channel",   # no tags
    "aws_config_rule",
    "aws_config_remediation_configuration",
    # IAM account-level (no tags)
    "aws_iam_account_password_policy",
    # CloudTrail sub-resources
    "aws_cloudtrail_event_data_store",
    # VPC sub-resources
    "aws_vpc_dhcp_options",
    "aws_vpc_dhcp_options_association",
    "aws_vpc_ipv4_cidr_block_association",
    "aws_main_route_table_association",
    # Security Hub
    "aws_securityhub_standards_subscription",
    "aws_securityhub_product_subscription",
    "aws_securityhub_member",
    # GuardDuty
    "aws_guardduty_publishing_destination",
    "aws_guardduty_member",
    # Inspector
    "aws_inspector_assessment_target",
    "aws_inspector_assessment_template",
})

# Suffix patterns for sub-resources that never support tags
BLOCKED_SUFFIXES = ("_rule", "_attachment", "_association", "_binding", "_status")

RESOURCE_START_RE = re.compile(
    r'^\s*resource\s+"([^"]+)"\s+"([^"]+)"\s*\{')


def _is_blocked(resource_type: str) -> bool:
    """Return True if this resource type must never receive a lifecycle block."""
    if resource_type in BLOCKED_TYPES:
        return True
    if any(resource_type.endswith(s) for s in BLOCKED_SUFFIXES):
        return True
    return False


def _should_inject(resource_type: str) -> bool:
    """Return True if this resource type should receive a lifecycle block."""
    if _is_blocked(resource_type):
        return False
    return resource_type in SAFE_TAGGABLE_TYPES or resource_type in SINGLETON_TYPES


def build_lifecycle_block(resource_type: str) -> list[str]:
    """Return lifecycle block lines for the given resource type."""
    indent = "  "
    lines = [f"{indent}lifecycle {{"]

    if resource_type in SINGLETON_TYPES:
        lines.append(f"{indent}  prevent_destroy = true")

    if resource_type in SAFE_TAGGABLE_TYPES:
        lines.append(f"{indent}  ignore_changes  = [tags, tags_all]")

    lines.append(f"{indent}}}")
    return lines


def inject_lifecycle(filepath: pathlib.Path):
    """Insert lifecycle blocks into allowlisted resource blocks that lack them."""
    text = filepath.read_text(encoding="utf-8")
    if not re.search(r'^\s*resource\s+"', text, re.MULTILINE):
        return  # no resource blocks

    lines = text.splitlines()
    out: list[str] = []
    depth = 0
    in_resource = False
    has_lifecycle = False
    current_rtype = ""
    in_heredoc = False
    heredoc_marker = None

    i = 0
    while i < len(lines):
        line = lines[i]

        # Track heredoc
        if in_heredoc:
            out.append(line)
            if line.strip() == heredoc_marker:
                in_heredoc = False
            i += 1
            continue

        hm = re.search(r'<<-?\s*([A-Za-z0-9_]+)\s*$', line)
        if hm:
            in_heredoc = True
            heredoc_marker = hm.group(1)
            out.append(line)
            delta = line.count('{') - line.count('}')
            depth += delta
            i += 1
            continue

        delta = line.count('{') - line.count('}')

        # Detect resource block start at depth 0
        if depth == 0:
            m = RESOURCE_START_RE.match(line)
            if m:
                in_resource = True
                has_lifecycle = False
                current_rtype = m.group(1)

        if in_resource and re.match(r'^\s*lifecycle\s*\{', line):
            has_lifecycle = True

        depth += delta

        # Resource block closing
        if in_resource and depth == 0:
            if not has_lifecycle and _should_inject(current_rtype):
                for lc_line in build_lifecycle_block(current_rtype):
                    out.append(lc_line)
            out.append(line)
            in_resource = False
            i += 1
            continue

        out.append(line)
        i += 1

    filepath.write_text("\n".join(out) + "\n", encoding="utf-8")


def main():
    directory = pathlib.Path(sys.argv[1])
    for tf_file in sorted(glob.glob(str(directory / "*.tf"))):
        p = pathlib.Path(tf_file)
        if p.name in ("backend.tf", "provider.tf", "data.tf"):
            continue
        inject_lifecycle(p)


if __name__ == "__main__":
    main()
