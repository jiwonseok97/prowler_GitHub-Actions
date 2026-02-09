# Enable log file validation on the existing CloudTrail trail
resource "aws_cloudtrail" "remediation_security_cloudtrail" {
  name                          = "security-cloudtail"
  s3_bucket_name                = "my-cloudtrail-logs-bucket"
  s3_key_prefix                 = "cloudtrail-logs"
  is_multi_region_trail         = true
  include_global_service_events = true
  enable_log_file_validation    = true
}

# Enforce least privilege on the CloudTrail logs bucket
resource "aws_s3_bucket_ownership_controls" "remediation_cloudtrail_logs_bucket" {
  bucket = "my-cloudtrail-logs-bucket"
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "remediation_cloudtrail_logs_bucket" {
  bucket = "my-cloudtrail-logs-bucket"
  acl    = "private"
  depends_on = [aws_s3_bucket_ownership_controls.remediation_cloudtrail_logs_bucket]
}

# Enable S3 Object Lock and MFA Delete on the CloudTrail logs bucket
resource "aws_s3_bucket_versioning" "remediation_cloudtrail_logs_bucket" {
  bucket = "my-cloudtrail-logs-bucket"
  versioning_configuration {
    status     = "Enabled"
    mfa_delete = "Enabled"
  }
}

resource "aws_s3_bucket_object_lock_configuration" "remediation_cloudtrail_logs_bucket" {
  bucket = "my-cloudtrail-logs-bucket"
  object_lock_enabled = "Enabled"
}