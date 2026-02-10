# Create a multi-region KMS key
resource "aws_kms_key" "remediation_multi_region_key" {
  description             = "Remediation multi-region KMS key"
  key_usage               = "ENCRYPT_DECRYPT"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  multi_region            = true
}

# Rotate the existing single-region KMS key to a multi-region key
resource "aws_kms_alias" "remediation_multi_region_key_alias" {
  name          = "alias/remediation-multi-region-key"
  target_key_id = aws_kms_key.remediation_multi_region_key.key_id
}

# Migrate resources using the existing single-region key to use the new multi-region key
# Update any references to the old key ID with the new multi-region key ID
# (e.g., in aws_s3_bucket_server_side_encryption_configuration, aws_lambda_function, etc.)