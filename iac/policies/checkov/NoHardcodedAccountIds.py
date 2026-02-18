"""CKV_CUSTOM_2: No hardcoded AWS account IDs in resource configurations.

AI-generated code sometimes embeds literal account IDs instead of using
data.aws_caller_identity.current.account_id.
"""
from __future__ import annotations

import re

from checkov.terraform.checks.resource.base_resource_check import BaseResourceCheck
from checkov.common.models.enums import CheckCategories, CheckResult

# 12-digit number pattern typical of AWS account IDs
ACCOUNT_ID_RE = re.compile(r"\b\d{12}\b")

# Exclude patterns that look like account IDs but aren't
SAFE_PATTERNS = {"000000000000", "123456789012"}


class NoHardcodedAccountIds(BaseResourceCheck):
    def __init__(self):
        name = "Do not hardcode AWS account IDs in resources"
        id = "CKV_CUSTOM_2"
        supported_resources = ["*"]
        categories = [CheckCategories.GENERAL_SECURITY]
        super().__init__(name=name, id=id, categories=categories,
                         supported_resources=supported_resources)

    def scan_resource_conf(self, conf) -> CheckResult:
        raw = str(conf)
        matches = ACCOUNT_ID_RE.findall(raw)
        for m in matches:
            if m not in SAFE_PATTERNS:
                return CheckResult.FAILED
        return CheckResult.PASSED


check = NoHardcodedAccountIds()
