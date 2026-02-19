# Create a new KMS key with multi-Region enabled
resource "aws_kms_key" "remediation_multi_region_key" {
  description              = "Remediation multi-Region KMS key"
  key_usage                = "ENCRYPT_DECRYPT"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  is_enabled               = true
  enable_key_rotation      = true
  multi_region             = true
}

# Rotate the existing single-Region KMS key to a multi-Region key
resource "aws_kms_key" "remediation_existing_key" {
  description              = "Existing single-Region KMS key"
  key_usage                = "ENCRYPT_DECRYPT"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  is_enabled               = true
  enable_key_rotation      = true
  multi_region             = true
}
