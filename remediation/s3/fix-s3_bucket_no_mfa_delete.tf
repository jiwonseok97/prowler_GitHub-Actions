# Enable MFA Delete on the S3 bucket
resource "aws_s3_bucket_versioning" "remediation_s3_bucket_versioning" {
  bucket = var.s3_bucket_name
  versioning_configuration {
    status     = "Enabled"
    mfa_delete = "Disabled"
  }
}

# Restrict version purge actions on the S3 bucket
resource "aws_s3_bucket_ownership_controls" "remediation_s3_bucket_ownership_controls" {
  bucket = var.s3_bucket_name
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}


variable "s3_bucket_name" {
  description = "Target S3 bucket name"
  type        = string
  default     = ""
}
