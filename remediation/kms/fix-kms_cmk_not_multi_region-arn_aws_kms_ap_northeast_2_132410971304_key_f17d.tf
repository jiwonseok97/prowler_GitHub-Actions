# Create a new multi-Region KMS key
resource "aws_kms_key" "remediation_multi_region_key" {
  description              = "Remediation multi-Region KMS key"
  key_usage                = "ENCRYPT_DECRYPT"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  multi_region             = true
}

# Replicate the existing single-Region KMS key to the new multi-Region key
resource "aws_kms_replica_key" "remediation_replica_key" {
  primary_key_arn = var.primary_key_arn
}

# Migrate resources using the existing single-Region key to the new multi-Region key
# (replace usages of the existing key with the new multi-Region key)

variable "primary_key_arn" {
  description = "primary_key_arn"
  type        = string
  default     = ""
}
