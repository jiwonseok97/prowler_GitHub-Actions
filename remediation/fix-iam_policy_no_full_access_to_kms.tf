# Modify an existing IAM policy to remove "kms:*" permission.
data "aws_iam_policy_document" "remediation_kms_readonly" {
  statement {
    effect = "Allow"
    actions = [
      "kms:Describe*",
      "kms:Get*",
      "kms:List*",
      "kms:RevokeGrant",
      "kms:ScheduleKeyDeletion"
    ]
    resources = [
      "arn:aws:kms:ap-northeast-2:${data.aws_caller_identity.current.account_id}:key/*"
    ]
  }
}

resource "aws_iam_policy_version" "remediation_kms_readonly" {
  count          = local.iam_do_kms ? 1 : 0
  policy_arn     = var.iam_kms_policy_arn
  policy         = data.aws_iam_policy_document.remediation_kms_readonly.json
  set_as_default = true
}
