"""CKV_CUSTOM_3: IAM policies must not use wildcard (*) actions.

AI-generated remediation code sometimes grants overly broad permissions
like "s3:*" or "iam:*" instead of least-privilege actions.
"""
from __future__ import annotations

import json

from checkov.terraform.checks.resource.base_resource_check import BaseResourceCheck
from checkov.common.models.enums import CheckCategories, CheckResult


class NoWildcardIamActions(BaseResourceCheck):
    def __init__(self):
        name = "IAM policies must not grant wildcard service actions"
        id = "CKV_CUSTOM_3"
        supported_resources = [
            "aws_iam_policy",
            "aws_iam_role_policy",
            "aws_iam_user_policy",
            "aws_iam_group_policy",
        ]
        categories = [CheckCategories.IAM]
        super().__init__(name=name, id=id, categories=categories,
                         supported_resources=supported_resources)

    def scan_resource_conf(self, conf) -> CheckResult:
        policy = conf.get("policy")
        if not policy:
            return CheckResult.PASSED

        if isinstance(policy, list):
            policy = policy[0] if policy else ""

        # Policy may be a JSON string or already parsed
        if isinstance(policy, str):
            try:
                policy = json.loads(policy)
            except (json.JSONDecodeError, TypeError):
                return CheckResult.UNKNOWN

        if not isinstance(policy, dict):
            return CheckResult.PASSED

        statements = policy.get("Statement", [])
        if not isinstance(statements, list):
            statements = [statements]

        for stmt in statements:
            if not isinstance(stmt, dict):
                continue
            if stmt.get("Effect", "").lower() != "allow":
                continue
            actions = stmt.get("Action", [])
            if isinstance(actions, str):
                actions = [actions]
            for action in actions:
                if not isinstance(action, str):
                    continue
                # Catch "s3:*", "iam:*", "*" etc.
                if action == "*" or (
                    ":" in action and action.split(":")[1] == "*"
                ):
                    return CheckResult.FAILED
        return CheckResult.PASSED


check = NoWildcardIamActions()
