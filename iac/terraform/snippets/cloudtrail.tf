# CloudTrail remediation for log bucket baseline
# Target log bucket: aws-cloudtrail-logs-132410971304-0971c04b

# Enforce versioning on the CloudTrail log bucket
resource "aws_s3_bucket_versioning" "remediation_cloudtrail_logs_versioning" {
  bucket = "aws-cloudtrail-logs-132410971304-0971c04b"
  versioning_configuration {
    status = "Enabled"
  }
}

# Enforce default encryption (SSE-S3)
resource "aws_s3_bucket_server_side_encryption_configuration" "remediation_cloudtrail_logs_encryption" {
  bucket = "aws-cloudtrail-logs-132410971304-0971c04b"
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "remediation_cloudtrail_logs_public_access_block" {
  bucket                  = "aws-cloudtrail-logs-132410971304-0971c04b"
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}
