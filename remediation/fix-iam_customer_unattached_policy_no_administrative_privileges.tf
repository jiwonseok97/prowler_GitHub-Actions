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
  count            = local.iam_do_unattached ? 1 : 0
  policy_arn       = var.iam_unattached_policy_arn
  policy           = data.aws_iam_policy_document.remediation_unattached_policy.json
  set_as_default   = true
}
