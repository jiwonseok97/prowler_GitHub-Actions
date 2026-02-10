# Create a new IAM policy with least-privilege permissions for KMS
resource "aws_iam_policy" "remediation_kms_policy" {
  name        = "remediation-kms-policy"
  description = "Least-privilege KMS permissions"
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

# Attach the new IAM policy to the existing IAM user
resource "aws_iam_user_policy_attachment" "remediation_kms_policy_attachment" {
  user       = "github-actions-prowler"
  policy_arn = aws_iam_policy.remediation_kms_policy.arn
}