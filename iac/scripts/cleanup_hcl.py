#!/usr/bin/env python3
"""Clean up AI-generated Terraform HCL files.

Strips provider blocks, computed attributes, deprecated S3 properties,
duplicate framework data sources, non-HCL prose, hardcoded account IDs,
hardcoded regions, and placeholder resource IDs.

Usage: python3 cleanup_hcl.py <file.tf> [<file2.tf> ...]
"""
import re, sys, pathlib

FRAMEWORK_DATA = {
    ('aws_caller_identity', 'current'),
    ('aws_region', 'current'),
    ('aws_partition', 'current'),
}

# AWS 계정 ID 패턴 (ARN 내부 12자리)
_ACCOUNT_ID_RE = re.compile(r"(?<=:)\d{12}(?=:)")

# placeholder VPC/subnet/SG ID 패턴
_PLACEHOLDER_PATTERNS = [
    (re.compile(r'"vpc-0123456789[a-f0-9]*"'), "var.vpc_id"),
    (re.compile(r'"subnet-0123456789[a-f0-9]*"'), "var.subnet_id"),
    (re.compile(r'"sg-0123456789[a-f0-9]*"'), "var.security_group_id"),
]

_PLACEHOLDER_SUBNET_LIST_RE = re.compile(
    r'\[\s*"subnet-0123456789[a-f0-9]*"'
    r'(?:\s*,\s*"subnet-0123456789[a-f0-9]*")*\s*\]'
)

_PLACEHOLDER_VALUES = [
    (re.compile(r'"example@example\.com"'), "var.notification_email"),
    (re.compile(r'"your-key-pair-name"'), "var.key_pair_name"),
    (re.compile(r'"YOUR_CLOUDTRAIL_LOG_GROUP_NAME"'), "var.cloudtrail_log_group_name"),
    (re.compile(r'"my-config-bucket"'), "var.config_bucket_name"),
]


def cleanup(path):
    lines = path.read_text().splitlines()
    out = []
    in_provider = False
    in_import = False
    in_heredoc = False
    heredoc_marker = None
    brace = 0
    import_brace = 0
    comment_tail = False
    in_s3_bucket = False
    s3_brace = 0
    in_dep_block = False
    dep_brace = 0
    skip_data = False
    data_brace = 0

    for line in lines:
        if in_heredoc:
            out.append(line)
            if line.strip() == heredoc_marker:
                in_heredoc = False
                heredoc_marker = None
            continue
        hm = re.search(r'<<-?\s*([A-Za-z0-9_]+)\s*$', line)
        if hm and not in_provider:
            in_heredoc = True
            heredoc_marker = hm.group(1)
            out.append(line)
            continue
        if skip_data:
            data_brace += line.count('{') - line.count('}')
            if data_brace <= 0:
                skip_data = False
            continue
        dm = re.match(r'^\s*data\s+"([^"]+)"\s+"([^"]+)"\s*\{', line)
        if dm and (dm.group(1), dm.group(2)) in FRAMEWORK_DATA:
            skip_data = True
            data_brace = line.count('{') - line.count('}')
            if data_brace <= 0:
                skip_data = False
            continue
        HCL_START = re.compile(
            r'^\s*(#|//|resource\b|data\b|provider\b|variable\b|locals\b|terraform\b|output\b|module\b|\})')
        if not comment_tail and re.match(r'^\s*(This|The)\s+.*Terraform code', line):
            comment_tail = True
        if comment_tail:
            if HCL_START.match(line):
                comment_tail = False
            else:
                out.append('# ' + line)
                continue
        if re.match(r'^\s*\d+\.\s', line):
            out.append('# ' + line)
            continue
        if not in_provider and re.match(r'^\s*provider\s+"aws"\s*\{', line):
            in_provider = True
            brace += line.count('{') - line.count('}')
            if brace <= 0:
                in_provider = False
            continue
        if in_provider:
            brace += line.count('{') - line.count('}')
            if brace <= 0:
                in_provider = False
            continue
        if not in_import and re.match(r'^\s*import\s*\{', line):
            in_import = True
            import_brace = line.count('{') - line.count('}')
            out.append(line)
            if import_brace <= 0:
                in_import = False
            continue
        if in_import:
            import_brace += line.count('{') - line.count('}')
            out.append(line)
            if import_brace <= 0:
                in_import = False
            continue
        if re.match(r'^\s*provider\s*=\s*aws\.\S+', line):
            continue
        if re.match(r'^\s*(arn|id|owner_id|unique_id|creation_date)\s*=', line):
            continue
        if not in_s3_bucket and re.match(r'^\s*resource\s+"aws_s3_bucket"\s+"[^"]+"\s*\{', line):
            in_s3_bucket = True
            s3_brace = line.count('{') - line.count('}')
            out.append(line)
            continue
        if in_s3_bucket:
            if in_dep_block:
                dep_brace += line.count('{') - line.count('}')
                s3_brace += line.count('{') - line.count('}')
                if dep_brace <= 0:
                    in_dep_block = False
                if s3_brace <= 0:
                    in_s3_bucket = False
                continue
            if re.match(r'^\s*acl\s*=', line):
                s3_brace += line.count('{') - line.count('}')
                if s3_brace <= 0:
                    in_s3_bucket = False
                continue
            if re.match(r'^\s*server_side_encryption_configuration\s*\{', line):
                in_dep_block = True
                dep_brace = line.count('{') - line.count('}')
                s3_brace += line.count('{') - line.count('}')
                if dep_brace <= 0:
                    in_dep_block = False
                if s3_brace <= 0:
                    in_s3_bucket = False
                continue
            s3_brace += line.count('{') - line.count('}')
            out.append(line)
            if s3_brace <= 0:
                in_s3_bucket = False
            continue
        out.append(line)

    # --- 후처리: 하드코딩 값 치환 ---
    result = []
    for line in out:
        stripped = line.lstrip()
        if stripped.startswith("#") or stripped.startswith("//"):
            result.append(line)
            continue
        # ARN 내 하드코딩된 계정 ID 치환
        if "arn:aws" in line and _ACCOUNT_ID_RE.search(line):
            line = _ACCOUNT_ID_RE.sub(
                "${data.aws_caller_identity.current.account_id}", line
            )
        # ARN 내 하드코딩된 리전 치환
        if "arn:aws" in line:
            line = re.sub(
                r"(arn:aws[^:]*:)([a-z]{2}-[a-z]+-\d)(?=:)",
                r"\1${data.aws_region.current.name}",
                line,
            )
        # placeholder VPC/subnet/SG ID 치환
        if _PLACEHOLDER_SUBNET_LIST_RE.search(line):
            line = _PLACEHOLDER_SUBNET_LIST_RE.sub("var.subnet_ids", line)
        for pat, replacement in _PLACEHOLDER_PATTERNS:
            if pat.search(line):
                line = pat.sub(replacement, line)
        # placeholder 이메일/키페어 치환
        for pat, replacement in _PLACEHOLDER_VALUES:
            if pat.search(line):
                line = pat.sub(replacement, line)
        result.append(line)

    path.write_text("\n".join(result) + "\n")

if __name__ == "__main__":
    for arg in sys.argv[1:]:
        cleanup(pathlib.Path(arg))
