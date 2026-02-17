#
# Remediate the "kms_cmk_not_multi_region" security finding
#

resource "aws_kms_key" "remediation_kms_key" {
  description              = "Remediation KMS key"
  key_usage                = "ENCRYPT_DECRYPT"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  multi_region             = true
  deletion_window_in_days  = 30
}
