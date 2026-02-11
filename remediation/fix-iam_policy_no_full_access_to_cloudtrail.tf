# Modify an existing IAM policy to remove "cloudtrail:*" permission.
# This remediation is gated to avoid failing apply when the target policy
# ARN is not provided.
variable "enable_remediation" {
  type    = bool
  default = false
}

variable "target_policy_arn" {
  type    = string
  default = ""
}

locals {
  do_remediate = var.enable_remediation && var.target_policy_arn != ""
}

data "aws_iam_policy_document" "remediation_cloudtrail_readonly" {
  statement {
    effect = "Allow"
    actions = [
      "cloudtrail:DescribeTrails",
      "cloudtrail:GetTrailStatus",
      "cloudtrail:LookupEvents"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy_version" "remediation_cloudtrail_readonly" {
  count          = local.do_remediate ? 1 : 0
  policy_arn     = var.target_policy_arn
  policy         = data.aws_iam_policy_document.remediation_cloudtrail_readonly.json
  set_as_default = true
}
