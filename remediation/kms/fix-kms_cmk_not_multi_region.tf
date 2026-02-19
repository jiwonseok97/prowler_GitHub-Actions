#
# Remediate the finding by converting the single-Region KMS key to a multi-Region key
#
resource "aws_kms_key" "remediation_multi_region_key" {
  description              = "Remediation: Multi-Region KMS key"
  key_usage                = "ENCRYPT_DECRYPT"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  multi_region             = true
}

#
# Rotate the existing single-Region key to the new multi-Region key
#
resource "aws_kms_alias" "remediation_multi_region_key_alias" {
  name          = "alias/alias-remediation-multi-region-key"
  target_key_id = aws_kms_key.remediation_multi_region_key.id
}
