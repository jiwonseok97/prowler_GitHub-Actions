#!/usr/bin/env python3
"""iam_builder.py — Patch IAM account-level settings.

Enforces:
  - Account password policy (CIS benchmarks)
  - Imports existing policy if present
"""
from __future__ import annotations

import textwrap
from .base import PatchBuilder, PatchResult, ImportCommand


class IAMBuilder(PatchBuilder):
    SERVICE = "iam"

    def build(self) -> PatchResult:
        imports: list[ImportCommand] = []
        parts = [self._hcl_provider()]

        # Password policy — always enforce (singleton resource)
        pw_exists = self.discovery.get("iam", {}).get("password_policy_exists", False)

        parts.append(textwrap.dedent("""\
            resource "aws_iam_account_password_policy" "strict" {
              minimum_password_length        = 14
              require_uppercase_characters   = true
              require_lowercase_characters   = true
              require_numbers                = true
              require_symbols                = true
              allow_users_to_change_password = true
              hard_expiry                    = false
              password_reuse_prevention      = 24
              max_password_age               = 90
            }
        """))

        if pw_exists:
            imports.append(ImportCommand(
                "aws_iam_account_password_policy.strict",
                "iam-account-password-policy",
            ))

        hcl = "\n".join(parts)
        return PatchResult(service=self.SERVICE, hcl=hcl, imports=imports)
