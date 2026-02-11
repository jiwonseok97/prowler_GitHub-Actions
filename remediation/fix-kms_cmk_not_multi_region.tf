# Create a multi-region KMS key
resource "aws_kms_key" "remediation_multi_region_key" {
  description             = "Remediation multi-region KMS key"
  key_usage               = "ENCRYPT_DECRYPT"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  multi_region            = true
}

# Update the existing single-region KMS key to be multi-region
resource "aws_kms_key" "remediation_existing_key" {
  multi_region            = true
}