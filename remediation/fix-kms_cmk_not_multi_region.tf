# Modify the existing KMS key to be multi-region
resource "aws_kms_key" "remediation_multi_region_key" {
  description             = "Remediated multi-region KMS key"
  key_usage               = "ENCRYPT_DECRYPT"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  multi_region            = true

  tags = {
    Environment = "production"
  }
}

# Update the existing KMS alias to point to the new multi-region key
resource "aws_kms_alias" "remediation_multi_region_key_alias" {
  name          = "alias/remediation-multi-region-key"
  target_key_id = aws_kms_key.remediation_multi_region_key.key_id
}