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
  count          = local.iam_do_cloudtrail ? 1 : 0
  policy_arn     = var.iam_cloudtrail_policy_arn
  policy         = data.aws_iam_policy_document.remediation_cloudtrail_readonly.json
  set_as_default = true
}
