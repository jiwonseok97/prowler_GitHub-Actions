# Modify the existing IAM policy to remove the "cloudtrail:*" permission
resource "aws_iam_policy" "remediation_kms_policy" {
  name        = "remediation-kms-policy"
  description = "Remediated IAM policy to remove cloudtrail:* permission"
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
        Resource = "*"
      }
    ]
  })
}

# Attach the modified IAM policy to the existing IAM user