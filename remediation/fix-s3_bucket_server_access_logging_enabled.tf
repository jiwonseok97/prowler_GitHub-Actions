# Create a new S3 bucket for storing server access logs
resource "aws_s3_bucket" "remediation_log_bucket" {
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
resource "aws_s3_bucket_logging" "remediation_s3_bucket_logging" {
  bucket        = "aws-cloudtrail-logs-132410971304-0971c04b"
  target_bucket = aws_s3_bucket.remediation_log_bucket.id
  target_prefix = "s3-access-logs/"
}

# Enable CloudTrail data events for the existing S3 bucket
resource "aws_cloudtrail" "remediation_cloudtrail" {
  name                          = "remediation-cloudtrail"
  s3_bucket_name                = "aws-cloudtrail-logs-132410971304-0971c04b"
  s3_key_prefix                 = "cloudtrail-logs"
  is_multi_region_trail         = true
  include_global_service_events = true

  event_selector {
    read_write_type           = "All"
    include_management_events = true

    data_resource {
      type   = "AWS::S3::Object"
      values = ["arn:aws:s3:::aws-cloudtrail-logs-132410971304-0971c04b/"]
    }
  }
}