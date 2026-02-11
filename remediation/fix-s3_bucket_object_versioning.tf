# Enable S3 versioning for the existing bucket
resource "aws_s3_bucket_versioning" "remediation_s3_bucket_versioning" {
  count  = local.s3_target_enabled ? 1 : 0
  bucket = local.s3_target_bucket_id
  versioning_configuration {
    status = "Enabled"
  }
}

# Apply a lifecycle rule to manage noncurrent versions
resource "aws_s3_bucket_lifecycle_configuration" "remediation_s3_bucket_lifecycle" {
  count  = local.s3_target_enabled ? 1 : 0
  bucket = local.s3_target_bucket_id
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
  count  = local.s3_target_enabled ? 1 : 0
  bucket = local.s3_target_bucket_id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "remediation_s3_bucket_public_access_block" {
  count  = local.s3_target_enabled ? 1 : 0
  bucket = local.s3_target_bucket_id
  block_public_acls       = true
  block_public_policy    = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
