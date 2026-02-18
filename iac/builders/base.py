#!/usr/bin/env python3
"""base.py — Patch Engine base builder.

Every service builder inherits from PatchBuilder and produces
Terraform HCL that *modifies existing AWS resources* rather than
creating new ones.

Design rules enforced by this base:
  - No count/for_each with optional variables
  - No default="" skip patterns
  - All resources reference discovered AWS objects
  - terraform import commands are emitted alongside HCL
"""
from __future__ import annotations

import json
import textwrap
from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any


@dataclass
class ImportCommand:
    """A single terraform import instruction."""
    address: str      # e.g. aws_s3_bucket_versioning.bucket_abc
    resource_id: str  # e.g. bucket-name


@dataclass
class PatchResult:
    """Output of a builder run."""
    service: str
    hcl: str                            # Terraform HCL code
    imports: list[ImportCommand] = field(default_factory=list)
    skip_reason: str | None = None      # if set, this service is skipped


class PatchBuilder(ABC):
    """Base class for all service patch builders."""

    # Subclass must set this
    SERVICE: str = ""

    def __init__(self, discovery: dict[str, Any], findings: list[dict]):
        self.discovery = discovery
        self.findings = findings
        self.account_id = discovery.get("account_id", "unknown")
        self.region = discovery.get("region", "ap-northeast-2")

    @abstractmethod
    def build(self) -> PatchResult:
        """Generate patch HCL + import commands for this service."""
        ...

    # ── Helpers ──────────────────────────────────────────

    def _hcl_backend(self) -> str:
        """Standard S3 backend block for this service."""
        return textwrap.dedent(f"""\
            terraform {{
              backend "s3" {{
                bucket         = "prowler-terraform-state-{self.account_id}"
                key            = "remediation/{self.SERVICE}.tfstate"
                region         = "{self.region}"
                dynamodb_table = "prowler-terraform-locks"
                encrypt        = true
              }}
            }}
        """)

    def _hcl_provider(self) -> str:
        return textwrap.dedent(f"""\
            provider "aws" {{
              region = "{self.region}"
            }}

            data "aws_caller_identity" "current" {{}}
            data "aws_region" "current" {{}}
            data "aws_partition" "current" {{}}
        """)

    def _finding_check_ids(self) -> set[str]:
        """Return set of check_ids from findings for this service."""
        return {f.get("CheckID", "") for f in self.findings}

    def _has_finding(self, *check_ids: str) -> bool:
        """Check if any of the given check_ids appear in findings."""
        found = self._finding_check_ids()
        return bool(found & set(check_ids))

    def _resource_ids_for_check(self, check_id: str) -> list[str]:
        """Return ResourceUID/ResourceId values for a specific check."""
        ids = []
        for f in self.findings:
            if f.get("CheckID") == check_id:
                rid = f.get("ResourceUID") or f.get("ResourceId") or ""
                if rid and rid not in ids:
                    ids.append(rid)
        return ids


def load_discovery(path: str = "/tmp/aws_discovery.json") -> dict:
    """Load discovery JSON."""
    p = Path(path)
    if p.exists():
        return json.loads(p.read_text())
    return {}


def load_findings(path: str) -> list[dict]:
    """Load processed Prowler findings (JSONL or JSON array)."""
    p = Path(path)
    if not p.exists():
        return []
    text = p.read_text().strip()
    if text.startswith("["):
        return json.loads(text)
    # JSONL
    results = []
    for line in text.splitlines():
        line = line.strip()
        if line:
            try:
                results.append(json.loads(line))
            except json.JSONDecodeError:
                pass
    return results
