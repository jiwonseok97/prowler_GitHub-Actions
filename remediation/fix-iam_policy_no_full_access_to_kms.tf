# Modify the existing IAM policy to remove the 'kms:*' privilege and add specific KMS actions
resource "aws_iam_policy" "remediation_iam_policy" {
  name        = "GitHubActionsProwlerRole-ProwlerReadOnly"
  description = "Custom IAM policy with limited KMS privileges"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
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
      },
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ],
        Resource = [
          "arn:aws:s3:::my-bucket-name/*",
          "arn:aws:s3:::my-bucket-name"
        ]
      }
    ]
  })
}

# Attach the modified IAM policy to the existing GitHubActionsProwlerRole