#
# Remediate the "kms_cmk_not_multi_region" security finding
#

resource "aws_kms_key" "remediation_multi_region_key" {
  description              = "Remediation multi-Region KMS key"
  key_usage                = "ENCRYPT_DECRYPT"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  multi_region             = true
}
