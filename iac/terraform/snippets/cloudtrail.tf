variable "s3_bucket_name" {
  description = "Existing CloudTrail log bucket name"
  type        = string
  default     = ""
}

locals {
  cloudtrail_bucket_enabled = var.s3_bucket_name != ""
}

# Enforce versioning on the target CloudTrail log bucket.
resource "aws_s3_bucket_versioning" "remediation_cloudtrail_logs_versioning" {
  count  = local.cloudtrail_bucket_enabled ? 1 : 0
  bucket = var.s3_bucket_name
  versioning_configuration {
    status = "Enabled"
  }
}

# Enforce default encryption (SSE-S3).
resource "aws_s3_bucket_server_side_encryption_configuration" "remediation_cloudtrail_logs_encryption" {
  count  = local.cloudtrail_bucket_enabled ? 1 : 0
  bucket = var.s3_bucket_name
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access.
resource "aws_s3_bucket_public_access_block" "remediation_cloudtrail_logs_public_access_block" {
  count  = local.cloudtrail_bucket_enabled ? 1 : 0
  bucket = var.s3_bucket_name
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}
