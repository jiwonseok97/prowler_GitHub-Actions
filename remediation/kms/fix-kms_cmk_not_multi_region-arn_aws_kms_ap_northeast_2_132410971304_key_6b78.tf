# Modify the existing KMS key to be multi-Region
resource "aws_kms_key" "remediation_kms_key" {
  description              = "Remediated KMS key"
  key_usage                = "ENCRYPT_DECRYPT"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  deletion_window_in_days  = 30
  is_enabled               = true
  enable_key_rotation      = true
  multi_region             = true
}
