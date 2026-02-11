# Create a new S3 bucket for server access logging
resource "aws_s3_bucket" "remediation_logging_bucket" {
  bucket = "aws-cloudtrail-logs-132410971304-0971c04b-logs"


  lifecycle_rule {
    enabled = true

    transition {
      days          = 30
      storage_class = "GLACIER"
    }

    expiration {
      days = 90
    }
  }
}

# Enable server access logging on the existing S3 bucket
resource "aws_s3_bucket_logging" "remediation_bucket_logging" {
  bucket        = "aws-cloudtrail-logs-132410971304-0971c04b"
  target_bucket = aws_s3_bucket.remediation_logging_bucket.id
  target_prefix = "s3-access-logs/"
}

# Enable CloudTrail data events on the existing S3 bucket
resource "aws_cloudtrail" "remediation_cloudtrail" {
  name                          = "remediation-cloudtrail"
  s3_bucket_name                = "aws-cloudtrail-logs-132410971304-0971c04b"
  s3_key_prefix                 = "cloudtrail-logs"
  is_multi_region_trail         = true
  include_global_service_events = true
  enable_log_file_validation    = true

  event_selector {
    read_write_type           = "All"
    include_management_events = true

    data_resource {
      type   = "AWS::S3::Object"
      values = ["arn:aws:s3:::aws-cloudtrail-logs-132410971304-0971c04b/"]
    }
  }
}

# Apply defense in depth by centralizing logs and protecting them from tampering
resource "aws_kms_key" "remediation_log_protection_key" {
  description             = "KMS key for protecting log files"
  deletion_window_in_days = 30
}

resource "aws_kms_alias" "remediation_log_protection_key_alias" {
  name          = "alias/remediation-log-protection-key"
  target_key_id = aws_kms_key.remediation_log_protection_key.id
}

resource "aws_s3_bucket_server_side_encryption_configuration" "remediation_logging_bucket_encryption" {
  bucket = aws_s3_bucket.remediation_logging_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.remediation_log_protection_key.id
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_ownership_controls" "remediation_logging_bucket_ownership" {
  bucket = aws_s3_bucket.remediation_logging_bucket.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "remediation_logging_bucket_acl" {
  bucket = aws_s3_bucket.remediation_logging_bucket.id
  acl    = "private"
}

resource "aws_s3_bucket_public_access_block" "remediation_logging_bucket_public_access_block" {
  bucket                  = aws_s3_bucket.remediation_logging_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}