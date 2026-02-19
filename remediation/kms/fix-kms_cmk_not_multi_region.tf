#
# Modify the existing KMS key to be multi-Region
#
resource "aws_kms_key" "remediation_kms_key" {
  description              = "Remediated KMS key"
  key_usage                = "ENCRYPT_DECRYPT"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  deletion_window_in_days  = 30
  is_enabled               = true
  enable_key_rotation      = true
  multi_region             = true

  tags = {
    Name = "Remediated KMS Key"
  }
}

#
# Update the KMS key alias to point to the new multi-Region key
#
resource "aws_kms_alias" "remediation_kms_key_alias" {
  name          = "alias/alias-remediated-kms-key"
  target_key_id = aws_kms_key.remediation_kms_key.id
}
