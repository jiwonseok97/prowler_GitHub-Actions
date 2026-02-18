#!/usr/bin/env python3
"""engine.py — Patch Engine orchestrator.

Replaces generate_remediation.py's IaC generation with a discovery-driven
patch approach. For each service with FAIL findings:

  1. Load AWS discovery data
  2. Load Prowler findings (filtered to FAIL)
  3. Run the service builder → produces HCL + import commands
  4. Write output to remediation/<service>/
  5. Write import script to remediation/<service>/imports.sh

Usage:
  python3 -m iac.builders.engine \\
    --discovery /tmp/aws_discovery.json \\
    --findings  mcp/output/prowler-output.json \\
    --outdir    remediation/
"""
from __future__ import annotations

import argparse
import json
import sys
from collections import defaultdict
from pathlib import Path

from .base import PatchBuilder, PatchResult, ImportCommand, load_discovery, load_findings
from .cloudwatch_builder import CloudWatchBuilder
from .cloudtrail_builder import CloudTrailBuilder
from .s3_builder import S3Builder
from .iam_builder import IAMBuilder
from .network_builder import NetworkBuilder


# Registry of all builders
BUILDERS: list[type[PatchBuilder]] = [
    IAMBuilder,
    S3Builder,
    CloudTrailBuilder,
    CloudWatchBuilder,
    NetworkBuilder,
]

# Map Prowler ServiceName → builder SERVICE
SERVICE_MAP = {
    "iam": "iam",
    "s3": "s3",
    "cloudtrail": "cloudtrail",
    "cloudwatch": "cloudwatch",
    "ec2": "network-ec2-vpc",
    "vpc": "network-ec2-vpc",
    "networkfirewall": "network-ec2-vpc",
}


def group_findings_by_service(findings: list[dict]) -> dict[str, list[dict]]:
    """Group FAIL findings by builder service name."""
    groups: dict[str, list[dict]] = defaultdict(list)
    for f in findings:
        if f.get("Status") != "FAIL":
            continue
        svc = f.get("ServiceName", "").lower()
        builder_svc = SERVICE_MAP.get(svc)
        if builder_svc:
            groups[builder_svc].append(f)
    return dict(groups)


def write_service_output(
    outdir: Path, result: PatchResult, account_id: str, region: str
) -> None:
    """Write HCL and import script for a service."""
    svc_dir = outdir / result.service
    svc_dir.mkdir(parents=True, exist_ok=True)

    # Clean previous files
    for old in svc_dir.glob("*.tf"):
        old.unlink()
    for old in svc_dir.glob("imports.sh"):
        old.unlink()

    # Write main.tf
    (svc_dir / "main.tf").write_text(result.hcl, encoding="utf-8")

    # Write backend.tf
    backend = f"""\
terraform {{
  backend "s3" {{
    bucket         = "prowler-terraform-state-{account_id}"
    key            = "remediation/{result.service}.tfstate"
    region         = "{region}"
    dynamodb_table = "prowler-terraform-locks"
    encrypt        = true
  }}
}}
"""
    (svc_dir / "backend.tf").write_text(backend, encoding="utf-8")

    # Write imports.sh
    if result.imports:
        lines = ["#!/usr/bin/env bash", "set -euo pipefail", ""]
        lines.append(f'WORK_DIR="${{1:-.}}"')
        lines.append("")
        for imp in result.imports:
            lines.append(f'echo "Importing {imp.address}..."')
            lines.append(
                f'terraform -chdir="$WORK_DIR" import -input=false '
                f'"{imp.address}" "{imp.resource_id}" 2>/dev/null || true'
            )
            lines.append("")
        (svc_dir / "imports.sh").write_text("\n".join(lines), encoding="utf-8")

    # Write manifest
    manifest = {
        "service": result.service,
        "files": [f.name for f in svc_dir.glob("*.tf")],
        "import_count": len(result.imports),
        "skip_reason": result.skip_reason,
    }
    (svc_dir / "manifest.json").write_text(
        json.dumps(manifest, indent=2), encoding="utf-8"
    )


def main():
    parser = argparse.ArgumentParser(description="Patch Engine — generate remediation HCL")
    parser.add_argument("--discovery", default="/tmp/aws_discovery.json")
    parser.add_argument("--findings", required=True)
    parser.add_argument("--outdir", default="remediation")
    args = parser.parse_args()

    discovery = load_discovery(args.discovery)
    if not discovery:
        print("ERROR: No discovery data found. Run preflight_discovery.sh first.")
        sys.exit(1)

    findings = load_findings(args.findings)
    if not findings:
        print("ERROR: No findings loaded.")
        sys.exit(1)

    account_id = discovery.get("account_id", "unknown")
    region = discovery.get("region", "ap-northeast-2")

    print(f"Loaded {len(findings)} findings, account={account_id}, region={region}")

    # Group findings by service
    grouped = group_findings_by_service(findings)
    print(f"Services with FAILs: {sorted(grouped.keys())}")

    outdir = Path(args.outdir)
    results: list[PatchResult] = []

    for BuilderClass in BUILDERS:
        svc = BuilderClass.SERVICE
        svc_findings = grouped.get(svc, [])
        if not svc_findings:
            print(f"  SKIP {svc}: no FAIL findings")
            continue

        print(f"  BUILD {svc}: {len(svc_findings)} findings")
        builder = BuilderClass(discovery, svc_findings)
        result = builder.build()

        if result.skip_reason:
            print(f"  SKIP {svc}: {result.skip_reason}")
            continue

        if not result.hcl.strip():
            print(f"  SKIP {svc}: empty HCL output")
            continue

        write_service_output(outdir, result, account_id, region)
        results.append(result)
        print(f"  OK   {svc}: {len(result.imports)} imports")

    print(f"\nGenerated {len(results)} service patches")

    # Summary
    for r in results:
        svc_dir = outdir / r.service
        tf_files = list(svc_dir.glob("*.tf"))
        print(f"  {r.service}: {len(tf_files)} tf files, {len(r.imports)} imports")

    return 0


if __name__ == "__main__":
    sys.exit(main())
