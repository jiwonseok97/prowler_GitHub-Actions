"""CKV_CUSTOM_1: Variables must not have empty string defaults.

AI-generated Terraform often sets `default = ""` for critical variables
like s3_bucket_name. Combined with `count = var.x != "" ? 1 : 0`, this
silently creates zero resources while reporting success.
"""
from __future__ import annotations

from checkov.terraform.checks.resource.base_resource_check import BaseResourceCheck
from checkov.common.models.enums import CheckCategories, CheckResult


class NoEmptyDefaultVariables(BaseResourceCheck):
    def __init__(self):
        name = "Variables must not use empty string defaults for resource-critical values"
        id = "CKV_CUSTOM_1"
        supported_resources = ["variable"]
        categories = [CheckCategories.GENERAL_SECURITY]
        super().__init__(name=name, id=id, categories=categories,
                         supported_resources=supported_resources)

    def scan_resource_conf(self, conf) -> CheckResult:
        default = conf.get("default")
        if default is None:
            return CheckResult.PASSED

        # Checkov wraps values in lists
        if isinstance(default, list):
            default = default[0] if default else None

        if default == "" or default == [""]:
            return CheckResult.FAILED
        return CheckResult.PASSED


check = NoEmptyDefaultVariables()
