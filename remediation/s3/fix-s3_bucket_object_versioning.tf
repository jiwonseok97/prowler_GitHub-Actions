# Enable S3 versioning for the existing S3 bucket
resource "aws_s3_bucket_versioning" "remediation_s3_bucket_versioning" {
  bucket = var.s3_bucket_name
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable S3 bucket encryption using the default KMS key
resource "aws_s3_bucket_server_side_encryption_configuration" "remediation_s3_bucket_encryption" {
  bucket = var.s3_bucket_name
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

# Apply a lifecycle rule to manage noncurrent object versions
resource "aws_s3_bucket_lifecycle_configuration" "remediation_s3_bucket_lifecycle" {
  bucket = var.s3_bucket_name
  rule {
    id = "lifecycle-rule-1"
    status = "Enabled"
    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}

variable "s3_bucket_name" {
  description = "Target S3 bucket name"
  type        = string
  default     = ""
}
