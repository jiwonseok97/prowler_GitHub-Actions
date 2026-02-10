# Create a new IAM policy with reduced permissions
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
        Resource = "arn:aws:dynamodb:ap-northeast-2:${data.aws_caller_identity.current.account_id}:table/my-dynamodb-table"
      }
    ]
  })
}

# Attach the new policy to the appropriate IAM user
resource "aws_iam_user_policy_attachment" "remediation_aws_learner_dynamodb_policy_attachment" {
  user       = "my-iam-user"
  policy_arn = aws_iam_policy.remediation_aws_learner_dynamodb_policy.arn
}