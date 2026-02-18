#!/usr/bin/env python3
"""s3_builder.py — Patch existing S3 buckets.

For each S3 bucket discovered in the account, enforce:
  - Server-side encryption (AES256 or KMS)
  - Versioning enabled
  - Public access block
  - SSL-only bucket policy
  - Access logging

Uses data sources to reference existing buckets, then applies
sub-resources that modify their configuration.
"""
from __future__ import annotations

import textwrap
from .base import PatchBuilder, PatchResult, ImportCommand


class S3Builder(PatchBuilder):
    SERVICE = "s3"

    def build(self) -> PatchResult:
        buckets = self.discovery.get("s3", {}).get("buckets", [])
        if not buckets:
            return PatchResult(
                service=self.SERVICE, hcl="", skip_reason="No S3 buckets found"
            )

        failing_checks = self._finding_check_ids()
        imports: list[ImportCommand] = []
        parts = [self._hcl_provider()]

        # Determine which patches are needed
        need_encryption = self._has_finding(
            "s3_bucket_default_encryption",
            "s3_bucket_kms_encryption",
        )
        need_versioning = self._has_finding("s3_bucket_object_versioning")
        need_public_block = self._has_finding("s3_bucket_acl_prohibited")
        need_ssl = self._has_finding("s3_bucket_secure_transport_policy")
        need_logging = self._has_finding("s3_bucket_server_access_logging_enabled")
        need_mfa = self._has_finding("s3_bucket_no_mfa_delete")

        # Skip terraform state bucket to avoid self-modification
        state_bucket = f"prowler-terraform-state-{self.account_id}"

        # Find or create a logging target bucket
        log_bucket = None
        for b in buckets:
            if b.endswith("-logs"):
                log_bucket = b
                break

        for bucket_name in buckets:
            if bucket_name == state_bucket:
                continue

            safe = bucket_name.replace("-", "_").replace(".", "_")

            # Data source — reference existing bucket
            parts.append(textwrap.dedent(f"""\
                data "aws_s3_bucket" "b_{safe}" {{
                  bucket = "{bucket_name}"
                }}
            """))

            # Encryption
            if need_encryption:
                res = f"aws_s3_bucket_server_side_encryption_configuration.enc_{safe}"
                parts.append(textwrap.dedent(f"""\
                    resource "aws_s3_bucket_server_side_encryption_configuration" "enc_{safe}" {{
                      bucket = data.aws_s3_bucket.b_{safe}.id
                      rule {{
                        apply_server_side_encryption_by_default {{
                          sse_algorithm = "AES256"
                        }}
                        bucket_key_enabled = true
                      }}
                    }}
                """))
                imports.append(ImportCommand(res, bucket_name))

            # Versioning
            if need_versioning or need_mfa:
                res = f"aws_s3_bucket_versioning.ver_{safe}"
                parts.append(textwrap.dedent(f"""\
                    resource "aws_s3_bucket_versioning" "ver_{safe}" {{
                      bucket = data.aws_s3_bucket.b_{safe}.id
                      versioning_configuration {{
                        status = "Enabled"
                      }}
                    }}
                """))
                imports.append(ImportCommand(res, bucket_name))

            # Public access block
            if need_public_block:
                res = f"aws_s3_bucket_public_access_block.pab_{safe}"
                parts.append(textwrap.dedent(f"""\
                    resource "aws_s3_bucket_public_access_block" "pab_{safe}" {{
                      bucket                  = data.aws_s3_bucket.b_{safe}.id
                      block_public_acls       = true
                      ignore_public_acls      = true
                      block_public_policy     = true
                      restrict_public_buckets = true
                    }}
                """))
                imports.append(ImportCommand(res, bucket_name))

            # SSL-only policy
            if need_ssl:
                parts.append(textwrap.dedent(f"""\
                    resource "aws_s3_bucket_policy" "ssl_{safe}" {{
                      bucket = data.aws_s3_bucket.b_{safe}.id
                      policy = jsonencode({{
                        Version = "2012-10-17"
                        Statement = [
                          {{
                            Sid       = "DenyInsecureTransport"
                            Effect    = "Deny"
                            Principal = "*"
                            Action    = "s3:*"
                            Resource  = [
                              data.aws_s3_bucket.b_{safe}.arn,
                              "${{data.aws_s3_bucket.b_{safe}.arn}}/*"
                            ]
                            Condition = {{
                              Bool = {{
                                "aws:SecureTransport" = "false"
                              }}
                            }}
                          }}
                        ]
                      }})
                    }}
                """))

            # Access logging
            if need_logging and log_bucket and bucket_name != log_bucket:
                parts.append(textwrap.dedent(f"""\
                    resource "aws_s3_bucket_logging" "log_{safe}" {{
                      bucket        = data.aws_s3_bucket.b_{safe}.id
                      target_bucket = "{log_bucket}"
                      target_prefix = "{bucket_name}/"
                    }}
                """))
                imports.append(ImportCommand(
                    f"aws_s3_bucket_logging.log_{safe}", bucket_name
                ))

        hcl = "\n".join(parts)
        return PatchResult(service=self.SERVICE, hcl=hcl, imports=imports)
