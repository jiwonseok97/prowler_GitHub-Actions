#!/usr/bin/env python3
"""inject_lifecycle.py — Inject lifecycle blocks into all resource blocks.

Enforces patch-only behavior for remediation:
  - Singleton/account resources: prevent_destroy = true
  - All resources: ignore_changes on cosmetic fields (tags, name) to prevent
    drift loops, but NEVER ignore security configuration fields.

Usage: python3 inject_lifecycle.py <directory>
"""
import re
import sys
import pathlib
import glob

# Singleton resource types: exactly one per account/region, always update-in-place
SINGLETON_TYPES = frozenset({
    "aws_iam_account_password_policy",
    "aws_securityhub_account",
    "aws_guardduty_detector",
    "aws_config_configuration_recorder",
    "aws_config_delivery_channel",
    "aws_config_configuration_recorder_status",
})

# Resource types that do NOT support tags — use ignore_changes = [] for these.
# Most AWS resources support tags, but IAM account-level and config sub-resources don't.
NO_TAGS_TYPES = frozenset({
    "aws_iam_account_password_policy",
    "aws_config_configuration_recorder",
    "aws_config_configuration_recorder_status",
    "aws_config_delivery_channel",
    "aws_s3_bucket_server_side_encryption_configuration",
    "aws_s3_bucket_versioning",
    "aws_s3_bucket_public_access_block",
    "aws_s3_bucket_ownership_controls",
    "aws_s3_bucket_policy",
    "aws_s3_bucket_lifecycle_configuration",
    "aws_s3_bucket_logging",
    "aws_kms_key_policy",
    "aws_kms_alias",
})

RESOURCE_START_RE = re.compile(
    r'^\s*resource\s+"([^"]+)"\s+"([^"]+)"\s*\{')


def build_lifecycle_block(resource_type: str) -> list[str]:
    """Return lifecycle block lines for the given resource type."""
    indent = "  "
    lines = [f"{indent}lifecycle {{"]

    if resource_type in SINGLETON_TYPES:
        lines.append(f"{indent}  prevent_destroy = true")

    # ignore_changes: tags only for resources that support them
    if resource_type in NO_TAGS_TYPES:
        lines.append(f"{indent}  ignore_changes  = []")
    else:
        lines.append(f"{indent}  ignore_changes  = [tags, tags_all]")

    lines.append(f"{indent}}}")
    return lines


def inject_lifecycle(filepath: pathlib.Path):
    """Insert lifecycle blocks into resource blocks that lack them."""
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
            if not has_lifecycle:
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
