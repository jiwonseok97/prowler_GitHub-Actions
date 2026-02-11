# Remove the unattached customer managed IAM policy that grants administrative privileges
resource "aws_iam_policy" "remediation_aws_learner_dynamodb_policy" {
  name        = "remediation_aws_learner_dynamodb_policy"
  description = "Remediation for unattached customer managed IAM policy with administrative privileges"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "dynamodb:*"
        ],
        Resource = [
          "arn:aws:dynamodb:ap-northeast-2:${data.aws_caller_identity.current.account_id}:table/*"
        ]
      }
    ]
  })
}

# Ensure the policy does not have administrative privileges
data "aws_iam_policy_document" "remediation_aws_learner_dynamodb_policy_document" {
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:*"
    ]
    resources = [
      "arn:aws:dynamodb:ap-northeast-2:${data.aws_caller_identity.current.account_id}:table/*"
    ]
  }
}