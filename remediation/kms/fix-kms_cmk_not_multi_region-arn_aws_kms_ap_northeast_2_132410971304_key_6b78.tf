# Modify the existing KMS key to be multi-Region
resource "aws_kms_key" "remediation_kms_key" {
  description              = "Remediated KMS key"
  key_usage                = "ENCRYPT_DECRYPT"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  deletion_window_in_days  = 30
  multi_region             = true
}
