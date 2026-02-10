# Create a new IAM policy with reduced KMS permissions
resource "aws_iam_policy" "remediation_kms_policy" {
  name        = "remediation-kms-policy"
  description = "Remediated IAM policy with reduced KMS permissions"
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
      }
    ]
  })
}

# Attach the new IAM policy to the existing user