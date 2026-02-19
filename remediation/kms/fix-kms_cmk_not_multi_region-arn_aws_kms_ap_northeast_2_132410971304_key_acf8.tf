# Create a new KMS key in the same Region as the existing key
resource "aws_kms_key" "remediation_kms_key" {
  description             = "Remediation KMS key"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  multi_region            = true
}

# Create an alias for the new KMS key
resource "aws_kms_alias" "remediation_kms_key_alias" {
  name          = "alias/alias-remediation-kms-key"
  target_key_id = aws_kms_key.remediation_kms_key.id
}

# Update the existing resources to use the new multi-Region KMS key
# (replace the existing key ID with the new key ID)
