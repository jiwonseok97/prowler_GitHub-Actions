# Create a new KMS key in the same Region as the existing key
resource "aws_kms_key" "remediation_multi_region_key" {
  description              = "Remediation multi-Region KMS key"
  key_usage                = "ENCRYPT_DECRYPT"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  deletion_window_in_days  = 30
  multi_region             = true
}

# Create an alias for the new multi-Region KMS key
resource "aws_kms_alias" "remediation_multi_region_key_alias" {
  name          = "alias/alias-remediation-multi-region-key"
  target_key_id = aws_kms_key.remediation_multi_region_key.id
}
