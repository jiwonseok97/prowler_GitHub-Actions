"""CKV_CUSTOM_4: No placeholder/example values in resource configurations.

AI-generated code frequently includes placeholder values like
"REPLACE_ME", "example.com", "your-bucket-name", "TODO" etc.
"""
from __future__ import annotations

import re

from checkov.terraform.checks.resource.base_resource_check import BaseResourceCheck
from checkov.common.models.enums import CheckCategories, CheckResult

PLACEHOLDER_PATTERNS = [
    r"REPLACE[-_]?ME",
    r"your[-_]",
    r"example\.com",
    r"my[-_]?(bucket|key|role|policy|topic|queue|trail|alarm|vpc|subnet)",
    r"<[A-Z_]+>",          # <ACCOUNT_ID>, <BUCKET_NAME>
    r"xxx+",
    r"TODO",
    r"FIXME",
    r"CHANGEME",
    r"INSERT[-_]",
    r"PLACEHOLDER",
]

PLACEHOLDER_RE = re.compile("|".join(PLACEHOLDER_PATTERNS), re.IGNORECASE)

# Keys that commonly have false positives (descriptions, comments)
SKIP_KEYS = {"description", "tags", "tags_all"}


class NoPlaceholderValues(BaseResourceCheck):
    def __init__(self):
        name = "Resources must not contain placeholder/example values"
        id = "CKV_CUSTOM_4"
        supported_resources = ["*"]
        categories = [CheckCategories.GENERAL_SECURITY]
        super().__init__(name=name, id=id, categories=categories,
                         supported_resources=supported_resources)

    def scan_resource_conf(self, conf) -> CheckResult:
        return self._check_dict(conf)

    def _check_dict(self, d, depth=0) -> CheckResult:
        if depth > 5 or not isinstance(d, dict):
            return CheckResult.PASSED
        for key, value in d.items():
            if key in SKIP_KEYS:
                continue
            if isinstance(value, str) and PLACEHOLDER_RE.search(value):
                return CheckResult.FAILED
            if isinstance(value, list):
                for item in value:
                    if isinstance(item, str) and PLACEHOLDER_RE.search(item):
                        return CheckResult.FAILED
                    if isinstance(item, dict):
                        r = self._check_dict(item, depth + 1)
                        if r == CheckResult.FAILED:
                            return CheckResult.FAILED
            if isinstance(value, dict):
                r = self._check_dict(value, depth + 1)
                if r == CheckResult.FAILED:
                    return CheckResult.FAILED
        return CheckResult.PASSED


check = NoPlaceholderValues()
