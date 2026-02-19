# Modify the existing KMS key to be multi-Region
resource "aws_kms_key" "remediation_kms_key" {
  description              = "Remediated KMS key"
  key_usage                = "ENCRYPT_DECRYPT"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  deletion_window_in_days  = 30
  is_enabled               = true
  enable_key_rotation      = true
  multi_region             = true
}

# Update the KMS key alias to match the new key
resource "aws_kms_alias" "remediation_kms_key_alias" {
  name          = "alias/alias-remediation-kms-key"
  target_key_id = aws_kms_key.remediation_kms_key.id
}

# Update the KMS key policy to allow necessary access
resource "aws_kms_key_policy" "remediation_kms_key_policy" {
  key_id = aws_kms_key.remediation_kms_key.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        Action   = "kms:*",
        Resource = "*"
      }
    ]
  })
}
