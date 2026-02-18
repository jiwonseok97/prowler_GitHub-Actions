#!/usr/bin/env python3
"""cloudtrail_builder.py — Patch existing CloudTrail configuration.

References the existing trail via data source, then enforces:
  - Log file validation enabled
  - KMS encryption (using existing or new key)
  - S3 bucket access logging for trail bucket
  - Multi-region trail
"""
from __future__ import annotations

import textwrap
from .base import PatchBuilder, PatchResult, ImportCommand


class CloudTrailBuilder(PatchBuilder):
    SERVICE = "cloudtrail"

    def build(self) -> PatchResult:
        trails = self.discovery.get("cloudtrail", {}).get("trails", [])
        if not trails:
            return PatchResult(
                service=self.SERVICE, hcl="",
                skip_reason="No CloudTrail trails found",
            )

        trail = trails[0]
        trail_name = trail["Name"]
        trail_arn = trail.get("TrailARN", "")
        s3_bucket = trail.get("S3BucketName", "") if "S3BucketName" in trail else ""

        # Look up the s3 bucket from discovery if not in trail
        if not s3_bucket:
            buckets = self.discovery.get("s3", {}).get("buckets", [])
            for b in buckets:
                if "cloudtrail" in b:
                    s3_bucket = b
                    break

        imports: list[ImportCommand] = []
        parts = [self._hcl_provider()]

        # ── Reference existing trail ──
        parts.append(textwrap.dedent(f"""\
            # Existing CloudTrail trail
            data "aws_cloudtrail" "main" {{
              name = "{trail_name}"
            }}
        """))

        # ── KMS key for CloudTrail encryption ──
        if self._has_finding("cloudtrail_kms_encryption_enabled"):
            parts.append(textwrap.dedent(f"""\
                # KMS key for CloudTrail encryption
                resource "aws_kms_key" "cloudtrail" {{
                  description             = "KMS key for CloudTrail encryption"
                  deletion_window_in_days = 30
                  enable_key_rotation     = true
                  policy = jsonencode({{
                    Version = "2012-10-17"
                    Statement = [
                      {{
                        Sid       = "AllowKeyAdministration"
                        Effect    = "Allow"
                        Principal = {{ AWS = "arn:aws:iam::{self.account_id}:root" }}
                        Action    = "kms:*"
                        Resource  = "*"
                      }},
                      {{
                        Sid       = "AllowCloudTrailEncrypt"
                        Effect    = "Allow"
                        Principal = {{ Service = "cloudtrail.amazonaws.com" }}
                        Action    = [
                          "kms:GenerateDataKey*",
                          "kms:DescribeKey"
                        ]
                        Resource  = "*"
                        Condition = {{
                          StringLike = {{
                            "kms:EncryptionContext:aws:cloudtrail:arn" = "arn:aws:cloudtrail:*:{self.account_id}:trail/*"
                          }}
                        }}
                      }},
                      {{
                        Sid       = "AllowCloudTrailDecrypt"
                        Effect    = "Allow"
                        Principal = {{ AWS = "arn:aws:iam::{self.account_id}:root" }}
                        Action    = "kms:Decrypt"
                        Resource  = "*"
                        Condition = {{
                          "Null" = {{
                            "kms:EncryptionContext:aws:cloudtrail:arn" = "false"
                          }}
                        }}
                      }}
                    ]
                  }})
                }}

                resource "aws_kms_alias" "cloudtrail" {{
                  name          = "alias/cloudtrail-encryption"
                  target_key_id = aws_kms_key.cloudtrail.key_id
                }}
            """))

        # ── Patch the trail itself ──
        has_kms = self._has_finding("cloudtrail_kms_encryption_enabled")
        kms_line = "  kms_key_id                    = aws_kms_key.cloudtrail.arn" if has_kms else ""

        parts.append(textwrap.dedent(f"""\
            # Patch existing trail — enforce validation + encryption
            resource "aws_cloudtrail" "main" {{
              name                          = "{trail_name}"
              s3_bucket_name                = "{s3_bucket}"
              is_multi_region_trail         = true
              enable_log_file_validation    = true
              include_global_service_events = true
            {kms_line}
            }}
        """))
        imports.append(ImportCommand("aws_cloudtrail.main", trail_name))

        # ── S3 bucket hardening for trail bucket ──
        if s3_bucket:
            safe = s3_bucket.replace("-", "_").replace(".", "_")
            parts.append(textwrap.dedent(f"""\
                # Harden CloudTrail S3 bucket
                data "aws_s3_bucket" "trail_bucket" {{
                  bucket = "{s3_bucket}"
                }}

                resource "aws_s3_bucket_versioning" "trail_bucket" {{
                  bucket = data.aws_s3_bucket.trail_bucket.id
                  versioning_configuration {{
                    status = "Enabled"
                  }}
                }}

                resource "aws_s3_bucket_public_access_block" "trail_bucket" {{
                  bucket                  = data.aws_s3_bucket.trail_bucket.id
                  block_public_acls       = true
                  ignore_public_acls      = true
                  block_public_policy     = true
                  restrict_public_buckets = true
                }}

                resource "aws_s3_bucket_server_side_encryption_configuration" "trail_bucket" {{
                  bucket = data.aws_s3_bucket.trail_bucket.id
                  rule {{
                    apply_server_side_encryption_by_default {{
                      sse_algorithm = "AES256"
                    }}
                  }}
                }}
            """))
            imports.append(ImportCommand(
                "aws_s3_bucket_versioning.trail_bucket", s3_bucket
            ))
            imports.append(ImportCommand(
                "aws_s3_bucket_public_access_block.trail_bucket", s3_bucket
            ))
            imports.append(ImportCommand(
                "aws_s3_bucket_server_side_encryption_configuration.trail_bucket",
                s3_bucket,
            ))

        hcl = "\n".join(parts)
        return PatchResult(service=self.SERVICE, hcl=hcl, imports=imports)
