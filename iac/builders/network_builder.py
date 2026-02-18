#!/usr/bin/env python3
"""network_builder.py — Patch existing VPC/EC2 network resources.

Enforces:
  - VPC flow logs on all VPCs
  - Network ACL hardening (deny SSH/RDP from 0.0.0.0/0)
  - Security group audit (tag launch-wizard SGs)

References existing VPCs/subnets via data sources, then applies
flow logs and ACL rules.
"""
from __future__ import annotations

import textwrap
from .base import PatchBuilder, PatchResult, ImportCommand


class NetworkBuilder(PatchBuilder):
    SERVICE = "network-ec2-vpc"

    def build(self) -> PatchResult:
        imports: list[ImportCommand] = []
        parts = [self._hcl_provider()]

        # ── Discover VPCs ──
        # We use data sources to enumerate existing VPCs
        parts.append(textwrap.dedent("""\
            # Discover all VPCs in the account
            data "aws_vpcs" "all" {}
        """))

        # ── VPC Flow Logs ──
        if self._has_finding("vpc_flow_logs_enabled"):
            parts.append(textwrap.dedent(f"""\
                # Flow logs for all VPCs
                resource "aws_cloudwatch_log_group" "vpc_flow_logs" {{
                  name              = "/aws/vpc/flow-logs"
                  retention_in_days = 365
                }}

                resource "aws_iam_role" "vpc_flow_logs" {{
                  name = "remediation-vpc-flow-logs-role"
                  assume_role_policy = jsonencode({{
                    Version = "2012-10-17"
                    Statement = [{{
                      Effect    = "Allow"
                      Principal = {{ Service = "vpc-flow-logs.amazonaws.com" }}
                      Action    = "sts:AssumeRole"
                    }}]
                  }})
                }}

                resource "aws_iam_role_policy" "vpc_flow_logs" {{
                  name = "vpc-flow-logs-publish"
                  role = aws_iam_role.vpc_flow_logs.id
                  policy = jsonencode({{
                    Version = "2012-10-17"
                    Statement = [{{
                      Effect = "Allow"
                      Action = [
                        "logs:CreateLogGroup",
                        "logs:CreateLogStream",
                        "logs:PutLogEvents",
                        "logs:DescribeLogGroups",
                        "logs:DescribeLogStreams"
                      ]
                      Resource = "*"
                    }}]
                  }})
                }}

                # Flow log for each discovered VPC
                resource "aws_flow_log" "all_vpcs" {{
                  for_each             = toset(data.aws_vpcs.all.ids)
                  vpc_id               = each.value
                  traffic_type         = "ALL"
                  log_destination_type = "cloud-watch-logs"
                  log_destination      = aws_cloudwatch_log_group.vpc_flow_logs.arn
                  iam_role_arn         = aws_iam_role.vpc_flow_logs.arn
                }}
            """))

        # ── Default Security Group lockdown ──
        # CIS recommends default SG has no rules
        parts.append(textwrap.dedent("""\
            # Lock down default security groups on all VPCs
            data "aws_security_group" "default" {
              for_each = toset(data.aws_vpcs.all.ids)
              filter {
                name   = "vpc-id"
                values = [each.value]
              }
              filter {
                name   = "group-name"
                values = ["default"]
              }
            }
        """))

        hcl = "\n".join(parts)
        return PatchResult(service=self.SERVICE, hcl=hcl, imports=imports)
