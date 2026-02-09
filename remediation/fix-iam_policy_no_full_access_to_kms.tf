# Create a new IAM policy with the required KMS permissions
resource "aws_iam_policy" "remediation_iam_policy_no_full_access_to_kms" {
  name        = "remediation_iam_policy_no_full_access_to_kms"
  description = "Remediation policy for finding iam_policy_no_full_access_to_kms"
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
        Resource = ["arn:aws:kms:ap-northeast-2:132410971304:key/*"]
      }
    ]
  })
}