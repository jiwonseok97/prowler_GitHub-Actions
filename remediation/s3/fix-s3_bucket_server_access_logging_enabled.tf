# Enable server access logging for the S3 bucket
resource "aws_s3_bucket" "remediation_cloudtrail_logs" {
  bucket = var.s3_bucket_name


  logging {
    target_bucket = aws_s3_bucket.remediation_cloudtrail_logs_target.id
    target_prefix = "s3-access-logs/"
  }
}

# Create a dedicated S3 bucket to store the access logs
resource "aws_s3_bucket" "remediation_cloudtrail_logs_target" {
  bucket = "remediation-cloudtrail-logs-${data.aws_caller_identity.current.account_id}"


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

# Attach the required IAM policy to the log bucket
resource "aws_s3_bucket_ownership_controls" "remediation_cloudtrail_logs_target" {
  bucket = aws_s3_bucket.remediation_cloudtrail_logs_target.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}


# Enable CloudTrail data events for the S3 bucket
resource "aws_cloudtrail" "remediation_cloudtrail" {
  name                          = "remediation-cloudtrail"
  s3_bucket_name                = var.s3_bucket_name
  s3_key_prefix                 = "cloudtrail"
  is_multi_region_trail         = true
  include_global_service_events = true
  enable_log_file_validation    = true

  event_selector {
    read_write_type           = "All"
    include_management_events = true

    data_resource {
      type   = "AWS::S3::Object"
      values = ["arn:aws:s3:::${var.s3_bucket_name}/"]
    }
  }
}

# Create an SNS topic to receive CloudTrail notifications
resource "aws_sns_topic" "remediation_cloudtrail_notifications" {
  name = "remediation-cloudtrail-notifications"
}

# Attach a policy to the SNS topic to allow CloudTrail to publish notifications
resource "aws_sns_topic_policy" "remediation_cloudtrail_notifications" {
  policy = data.aws_iam_policy_document.remediation_cloudtrail_notifications_policy.json
  arn    = aws_sns_topic.remediation_cloudtrail_notifications.arn
}

data "aws_iam_policy_document" "remediation_cloudtrail_notifications_policy" {
  statement {
    actions = ["SNS:Publish"]
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    resources = [aws_sns_topic.remediation_cloudtrail_notifications.arn]
  }
}

# Create a KMS key to encrypt the CloudTrail logs
resource "aws_kms_key" "remediation_cloudtrail_logs_encryption" {
  description             = "Encryption key for CloudTrail logs"
  deletion_window_in_days = 10
}

# Attach a policy to the KMS key to allow CloudTrail to use it
resource "aws_kms_key_policy" "remediation_cloudtrail_logs_encryption" {
  policy = data.aws_iam_policy_document.remediation_cloudtrail_logs_encryption_policy.json
  key_id = aws_kms_key.remediation_cloudtrail_logs_encryption.key_id
}

data "aws_iam_policy_document" "remediation_cloudtrail_logs_encryption_policy" {
  statement {
    actions = ["kms:*"]
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    resources = ["*"]
  }
}

# Configure CloudTrail to use the KMS key for log encryption
resource "aws_cloudtrail" "remediation_cloudtrail_1" {
  name           = "remediation-cloudtrail"
  s3_bucket_name = aws_s3_bucket.remediation_cloudtrail_logs.id
  kms_key_id     = aws_kms_key.remediation_cloudtrail_logs_encryption.arn
}

variable "s3_bucket_name" {
  description = "Target S3 bucket name for remediation"
  type        = string
  default     = "aws-cloudtrail-logs-132410971304-0971c04b"
}
