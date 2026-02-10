# Create a new IAM policy with limited permissions
resource "aws_iam_policy" "remediation_limited_policy" {
  name        = "remediation_limited_policy"
  description = "Limited IAM policy without administrative privileges"
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
        Resource = "arn:aws:dynamodb:ap-northeast-2:${data.aws_caller_identity.current.account_id}:table/my-table"
      }
    ]
  })
}
