# Enable default encryption on the S3 bucket
resource "aws_s3_bucket_ownership_controls" "remediation_s3_bucket_ownership_controls" {
  bucket = "aws-cloudtrail-logs-132410971304-0971c04b"
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "remediation_s3_bucket_public_access_block" {
  bucket = "aws-cloudtrail-logs-132410971304-0971c04b"
  block_public_acls       = true
  block_public_policy    = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_kms_key" "remediation_s3_encryption_key" {
  description             = "KMS key for S3 bucket encryption"
  deletion_window_in_days = 10
}

resource "aws_s3_bucket_server_side_encryption_configuration" "remediation_s3_bucket_encryption" {
  bucket = "aws-cloudtrail-logs-132410971304-0971c04b"
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.remediation_s3_encryption_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}