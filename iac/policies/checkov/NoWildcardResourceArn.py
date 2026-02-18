"""CKV_CUSTOM_5: IAM policies must not use Resource: "*" with dangerous actions.

AI-generated code often grants broad permissions on all resources.
Resource: "*" is acceptable for read-only/list actions but not for
mutating actions like Put*, Delete*, Create*, etc.
"""
from __future__ import annotations

import json

from checkov.terraform.checks.resource.base_resource_check import BaseResourceCheck
from checkov.common.models.enums import CheckCategories, CheckResult

DANGEROUS_PREFIXES = (
    "Put", "Delete", "Create", "Update", "Remove", "Attach",
    "Detach", "Add", "Set", "Modify", "Terminate", "Run",
    "Start", "Stop", "Reboot",
)


class NoWildcardResourceArn(BaseResourceCheck):
    def __init__(self):
        name = "IAM policies must not grant dangerous actions on Resource *"
        id = "CKV_CUSTOM_5"
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

            resources = stmt.get("Resource", [])
            if isinstance(resources, str):
                resources = [resources]
            if "*" not in resources:
                continue

            actions = stmt.get("Action", [])
            if isinstance(actions, str):
                actions = [actions]
            for action in actions:
                if not isinstance(action, str) or ":" not in action:
                    continue
                action_name = action.split(":")[1]
                if any(action_name.startswith(p) for p in DANGEROUS_PREFIXES):
                    return CheckResult.FAILED

        return CheckResult.PASSED


check = NoWildcardResourceArn()
