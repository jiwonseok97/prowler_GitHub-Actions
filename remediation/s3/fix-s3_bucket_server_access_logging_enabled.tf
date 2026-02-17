# Enable server access logging for the S3 bucket
resource "aws_s3_bucket" "remediation_cloudtrail_logs" {
  bucket = var.s3_bucket_name


  logging {
    target_bucket = aws_s3_bucket.remediation_cloudtrail_logs_logging.id
    target_prefix = "s3-access-logs/"
  }
}

# Create a dedicated S3 bucket for storing the access logs
resource "aws_s3_bucket" "remediation_cloudtrail_logs_logging" {
  bucket = "${var.s3_bucket_name}-logs"


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

# Enable CloudTrail data events for the S3 bucket
resource "aws_cloudtrail" "remediation_cloudtrail" {
  name                          = "remediation-cloudtrail"
  s3_bucket_name                = aws_s3_bucket.remediation_cloudtrail_logs.id
  s3_key_prefix                 = "cloudtrail"
  is_multi_region_trail         = true
  include_global_service_events = true

  event_selector {
    read_write_type           = "All"
    include_management_events = true

    data_resource {
      type   = "AWS::S3::Object"
      values = ["arn:aws:s3:::${var.s3_bucket_name}/*"]
    }
  }
}

# Create an SNS topic and subscription for CloudTrail log monitoring
resource "aws_sns_topic" "remediation_cloudtrail_logs_topic" {
  name = "remediation-cloudtrail-logs-topic"
}

resource "aws_sns_topic_subscription" "remediation_cloudtrail_logs_subscription" {
  topic_arn = aws_sns_topic.remediation_cloudtrail_logs_topic.arn
  protocol  = "email"
  endpoint  = var.cloudtrail_logs_notification_email
}

# Create a KMS key for encrypting the CloudTrail logs
resource "aws_kms_key" "remediation_cloudtrail_logs_kms_key" {
  description             = "CloudTrail Logs KMS Key"
  deletion_window_in_days = 30
}

resource "aws_kms_alias" "remediation_cloudtrail_logs_kms_key_alias" {
  name          = "alias/alias-remediation-cloudtrail-logs-kms-key"
  target_key_id = aws_kms_key.remediation_cloudtrail_logs_kms_key.id
}

# Apply the KMS key to the CloudTrail logs bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "remediation_cloudtrail_logs_encryption" {
  bucket = aws_s3_bucket.remediation_cloudtrail_logs.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.remediation_cloudtrail_logs_kms_key.id
      sse_algorithm     = "aws:kms"
    }
  }
}

# Apply the KMS key to the CloudTrail logs bucket
resource "aws_s3_bucket_ownership_controls" "remediation_cloudtrail_logs_ownership" {
  bucket = aws_s3_bucket.remediation_cloudtrail_logs.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}


# Apply the KMS key to the CloudTrail logs bucket
resource "aws_s3_bucket_public_access_block" "remediation_cloudtrail_logs_public_access_block" {
  bucket = aws_s3_bucket.remediation_cloudtrail_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

variable "s3_bucket_name" {
  description = "Target S3 bucket name for remediation"
  type        = string
  default     = "aws-cloudtrail-logs-132410971304-0971c04b"
}


resource "aws_s3_bucket_policy" "remediation_cloudtrail_bucket_policy" {
  bucket = aws_s3_bucket.remediation_cloudtrail_logs.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AWSCloudTrailAclCheck"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:GetBucketAcl"
        Resource  = "arn:aws:s3:::${aws_s3_bucket.remediation_cloudtrail_logs.id}"
      },
      {
        Sid       = "AWSCloudTrailWrite"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = "arn:aws:s3:::${aws_s3_bucket.remediation_cloudtrail_logs.id}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

variable "cloudtrail_logs_notification_email" {
  description = "cloudtrail_logs_notification_email"
  type        = string
  default     = ""
}
