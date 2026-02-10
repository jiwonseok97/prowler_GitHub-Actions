# Remediation: ensure customer-managed policies don't grant admin privileges
# NOTE: The original AI-generated code referenced a non-existent user (my-iam-user).
# This creates a reduced-permissions policy template only.

resource "aws_iam_policy" "remediation_aws_learner_dynamodb_policy" {
  name        = "remediation_aws_learner_dynamodb_policy"
  description = "Remediated IAM policy with reduced permissions"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "dynamodb:DescribeTable",
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem"
        ],
        Resource = "arn:aws:dynamodb:ap-northeast-2:${data.aws_caller_identity.current.account_id}:table/*"
      }
    ]
  })
}
