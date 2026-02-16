# Enable S3 versioning for the existing S3 bucket
resource "aws_s3_bucket_versioning" "remediation_s3_bucket_versioning" {
  bucket = var.s3_bucket_name
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable S3 bucket encryption using a new KMS key
resource "aws_kms_key" "remediation_s3_bucket_encryption_key" {
  description             = "KMS key for S3 bucket encryption"
  deletion_window_in_days = 10
}

resource "aws_s3_bucket_server_side_encryption_configuration" "remediation_s3_bucket_encryption" {
  bucket = var.s3_bucket_name
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.remediation_s3_bucket_encryption_key.id
      sse_algorithm     = "aws:kms"
    }
  }
}

# Enable S3 bucket logging to a new S3 bucket
resource "aws_s3_bucket" "remediation_s3_bucket_logs" {
  bucket = "remediation-s3-bucket-logs-${data.aws_caller_identity.current.account_id}"
}

resource "aws_s3_bucket_ownership_controls" "remediation_s3_bucket_logs_ownership" {
  bucket = aws_s3_bucket.remediation_s3_bucket_logs.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}


resource "aws_s3_bucket_public_access_block" "remediation_s3_bucket_logs_public_access_block" {
  bucket                  = aws_s3_bucket.remediation_s3_bucket_logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_logging" "remediation_s3_bucket_logging" {
  bucket        = var.s3_bucket_name
  target_bucket = aws_s3_bucket.remediation_s3_bucket_logs.id
  target_prefix = "s3-logs/"
}

variable "s3_bucket_name" {
  description = "Target S3 bucket name"
  type        = string
  default     = ""
}
