# Enable server access logging for the S3 bucket
resource "aws_s3_bucket" "remediation_cloudtrail_logs" {
  bucket = var.s3_bucket_name


  logging {
    target_bucket = aws_s3_bucket.remediation_cloudtrail_logs_destination.id
    target_prefix = "s3-access-logs/"
  }
}

# Create a dedicated S3 bucket to store the server access logs
resource "aws_s3_bucket" "remediation_cloudtrail_logs_destination" {
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

# Enable CloudTrail data events for the S3 bucket
resource "aws_cloudtrail" "remediation_cloudtrail" {
  name                          = "remediation-cloudtrail-data.aws_caller_identity.current.account_id"
  s3_bucket_name                = aws_s3_bucket.remediation_cloudtrail_logs.id
  s3_key_prefix                 = "cloudtrail"
  is_multi_region_trail         = true
  include_global_service_events = true

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
  name = "remediation-cloudtrail-notifications-data.aws_caller_identity.current.account_id"
}

# Attach a policy to the SNS topic to allow CloudTrail to publish notifications
resource "aws_sns_topic_policy" "remediation_cloudtrail_notifications_policy" {

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        },
        Action   = "SNS:Publish",
        Resource = aws_sns_topic.remediation_cloudtrail_notifications.arn
      }
    ]
  })
  arn = aws_sns_topic.remediation_cloudtrail_notifications.arn
}

# Create a KMS key to encrypt the CloudTrail logs
resource "aws_kms_key" "remediation_cloudtrail_logs_key" {
  description             = "KMS key for CloudTrail logs"
  deletion_window_in_days = 30
}

# Attach a policy to the KMS key to allow CloudTrail to use it
resource "aws_kms_key_policy" "remediation_cloudtrail_logs_key_policy" {

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        },
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ],
        Resource = "*"
      }
    ]
  })
  key_id = aws_kms_key.remediation_cloudtrail_logs_key.key_id
}

# Configure CloudTrail to use the KMS key for encryption
resource "aws_cloudtrail" "remediation_cloudtrail_1" {
  name           = "remediation-cloudtrail"
  s3_bucket_name = aws_s3_bucket.remediation_cloudtrail_logs.id
  # ... (existing configuration)
  kms_key_id = aws_kms_key.remediation_cloudtrail_logs_key.id
}

# Configure the S3 bucket to use the KMS key for server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "remediation_cloudtrail_logs_encryption" {
  bucket = aws_s3_bucket.remediation_cloudtrail_logs.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.remediation_cloudtrail_logs_key.id
      sse_algorithm     = "aws:kms"
    }
  }
}

# Configure the S3 bucket destination to use the KMS key for server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "remediation_cloudtrail_logs_destination_encryption" {
  bucket = aws_s3_bucket.remediation_cloudtrail_logs_destination.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.remediation_cloudtrail_logs_key.id
      sse_algorithm     = "aws:kms"
    }
  }
}

# Configure the S3 bucket ACL to be private

# Configure the S3 bucket destination ACL to be private

# Configure the CloudTrail to send notifications to the SNS topic
resource "aws_cloudtrail" "remediation_cloudtrail_2" {
  name           = "remediation-cloudtrail"
  s3_bucket_name = aws_s3_bucket.remediation_cloudtrail_logs.id
  # ... (existing configuration)
  sns_topic_name = aws_sns_topic.remediation_cloudtrail_notifications.name
}

# Configure the SNS topic subscription to receive CloudTrail notifications
resource "aws_sns_topic_subscription" "remediation_cloudtrail_notifications_subscription" {
  topic_arn = aws_sns_topic.remediation_cloudtrail_notifications.arn
  protocol  = "email"
  endpoint  = var.notification_email
}

variable "s3_bucket_name" {
  description = "Target S3 bucket name for remediation"
  type        = string
  default     = "aws-cloudtrail-logs-132410971304-0971c04b"
}


variable "notification_email" {
  description = "notification_email"
  type        = string
  default     = ""
}
