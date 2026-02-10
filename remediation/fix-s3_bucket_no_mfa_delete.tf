# Enable MFA Delete on the S3 bucket
resource "aws_s3_bucket_versioning" "remediation_s3_bucket_versioning" {
  bucket = "aws-cloudtrail-logs-132410971304-0971c04b"
  versioning_configuration {
    status = "Enabled"
    mfa_delete = "Enabled"
  }
}

# Restrict version purge actions on the S3 bucket
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