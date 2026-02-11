# Remediate an unattached, overly permissive policy by replacing its default
# version with a least-privilege document. This is intentionally gated to
# avoid failing apply when a target policy ARN is not provided.
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

data "aws_iam_policy_document" "remediation_unattached_policy" {
  statement {
    effect = "Deny"
    actions = [
      "iam:*",
      "sts:*"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy_version" "remediation_unattached_policy" {
  count            = local.do_remediate ? 1 : 0
  policy_arn       = var.target_policy_arn
  policy           = data.aws_iam_policy_document.remediation_unattached_policy.json
  set_as_default   = true
}
