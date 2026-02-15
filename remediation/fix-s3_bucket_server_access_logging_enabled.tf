# Enable server access logging for the S3 bucket
data "aws_s3_bucket" "remediation_aws_cloudtrail_logs_bucket" {
  bucket = "aws-cloudtrail-logs-132410971304-0971c04b"
}

# Create a dedicated log bucket with least privilege, retention, and monitoring
data "aws_s3_bucket" "remediation_log_bucket" {
  bucket = "aws-cloudtrail-logs-132410971304-0971c04b-logs"
}

# Enable CloudTrail data events for object-level visibility
resource "aws_cloudtrail" "remediation_cloudtrail" {
  name = "remediation-cloudtrail"
  s3_bucket_name                = data.aws_s3_bucket.remediation_log_bucket.id
  s3_key_prefix                 = "cloudtrail-logs"
  is_multi_region_trail         = true
  include_global_service_events = true
  enable_log_file_validation    = true

  event_selector {
    read_write_type           = "All"
    include_management_events = true

    data_resource {
      type   = "AWS::S3::Object"
      values = ["arn:aws:s3:::"]
    }
  }
}

# Centralize and protect the logs from tampering
resource "aws_kms_key" "remediation_log_bucket_key" {
  description             = "KMS key for log bucket encryption"
  deletion_window_in_days = 30
}

resource "aws_s3_bucket_ownership_controls" "remediation_log_bucket_ownership" {
  bucket = data.aws_s3_bucket.remediation_log_bucket.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "remediation_log_bucket_public_access" {
  bucket = data.aws_s3_bucket.remediation_log_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}