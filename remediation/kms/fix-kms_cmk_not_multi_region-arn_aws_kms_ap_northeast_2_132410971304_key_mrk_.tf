# Create a new multi-Region KMS key
resource "aws_kms_key" "remediation_multi_region_key" {
  description              = "Remediation multi-Region KMS key"
  key_usage                = "ENCRYPT_DECRYPT"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  multi_region             = true
}

# Replicate the new multi-Region key to the current Region
resource "aws_kms_replica_key" "remediation_multi_region_key_replica" {
  description     = "Remediation multi-Region KMS key replica"
  primary_key_arn = aws_kms_key.remediation_multi_region_key.arn
  tags = {
    Environment = "Remediation"
  }
}

# Update the existing single-Region key to be multi-Region
resource "aws_kms_key" "remediation_existing_key" {
  description              = "Existing KMS key (updated to multi-Region)"
  key_usage                = "ENCRYPT_DECRYPT"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  multi_region             = true
}
