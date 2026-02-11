# Enable S3 versioning for the existing bucket
resource "aws_s3_bucket_versioning" "remediation_s3_bucket_versioning" {
  bucket = "aws-cloudtrail-logs-132410971304-0971c04b"
  versioning_configuration {
    status = "Enabled"
  }
}

# Apply a lifecycle rule to manage noncurrent versions
resource "aws_s3_bucket_lifecycle_configuration" "remediation_s3_bucket_lifecycle" {
  bucket = "aws-cloudtrail-logs-132410971304-0971c04b"
  rule {
    id = "lifecycle-rule-1"
    status = "Enabled"
    noncurrent_version_expiration {
      noncurrent_days = 30 # Set the desired number of days to retain noncurrent versions
    }
  }
}

# Enable MFA Delete for stronger protection
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