# Create a new multi-region KMS customer managed key
resource "aws_kms_key" "remediation_multi_region_key" {
  description             = "Remediation multi-region KMS key"
  key_usage               = "ENCRYPT_DECRYPT"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  multi_region            = true
}

# Create a new IAM policy to allow access to the multi-region KMS key
resource "aws_iam_policy" "remediation_multi_region_key_policy" {
  name        = "remediation-multi-region-key-policy"
  description = "Allows access to the remediation multi-region KMS key"
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
        Resource = aws_kms_key.remediation_multi_region_key.arn
      }
    ]
  })
}