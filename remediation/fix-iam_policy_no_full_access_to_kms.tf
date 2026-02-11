# Modify the existing IAM policy to remove the 'kms:*' privilege
resource "aws_iam_policy" "remediation_aws_learner_dynamodb_policy" {
  name        = "remediation_aws_learner_dynamodb_policy"
  description = "Remediated IAM policy to remove 'kms:*' privilege"
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
      },
      {
        Effect = "Allow",
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ],
        Resource = [
          "arn:aws:kms:ap-northeast-2:${data.aws_caller_identity.current.account_id}:key/*"
        ]
      }
    ]
  })
}

# Attach the remediated IAM policy to the existing IAM user