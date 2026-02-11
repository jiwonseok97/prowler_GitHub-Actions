# Create a multi-Region KMS key
resource "aws_kms_key" "remediation_multi_region_key" {
  description             = "Remediation multi-Region KMS key"
  key_usage               = "ENCRYPT_DECRYPT"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  multi_region            = true
}

# Update the existing single-Region KMS key to be multi-Region
resource "aws_kms_key" "remediation_existing_key" {
  multi_region            = true
}