# Create a new KMS key with multi-Region enabled
resource "aws_kms_key" "remediation_kms_key" {
  description              = "Remediation multi-Region KMS key"
  key_usage                = "ENCRYPT_DECRYPT"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  multi_region             = true
}

# Create an alias for the new KMS key
resource "aws_kms_alias" "remediation_kms_key_alias" {
  name = "alias/alias-alias-remediation-kms-key"
  target_key_id = aws_kms_key.remediation_kms_key.id
}

# Update the existing KMS key to use the new multi-Region key
resource "aws_kms_key" "remediation_existing_kms_key" {
  deletion_window_in_days = 30
  multi_region            = true
  depends_on              = [aws_kms_key.remediation_kms_key]
}
