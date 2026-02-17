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

}

# Enable CloudTrail data events for the S3 bucket
resource "aws_cloudtrail" "remediation_cloudtrail" {
  name                          = "remediation-cloudtrail-data.aws_caller_identity.current.account_id"
  s3_bucket_name                = var.s3_bucket_name
  s3_key_prefix                 = "cloudtrail"
  include_global_service_events = true
  is_multi_region_trail         = true
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

# Attach the CloudTrail policy to the S3 bucket
resource "aws_s3_bucket_policy" "remediation_cloudtrail_logs_policy" {
  bucket = aws_s3_bucket.remediation_cloudtrail_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = "arn:aws:s3:::${var.s3_bucket_name}"
      },
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "arn:aws:s3:::${var.s3_bucket_name}/cloudtrail/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
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
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "sns:Publish"
        Resource = aws_sns_topic.remediation_cloudtrail_notifications.arn
      }
    ]
  })
  arn = aws_sns_topic.remediation_cloudtrail_notifications.arn
}

# Create a KMS key to encrypt the CloudTrail logs
resource "aws_kms_key" "remediation_cloudtrail_logs_kms_key" {
  description             = "KMS key for CloudTrail logs encryption"
  deletion_window_in_days = 30
}

# Attach a policy to the KMS key to allow CloudTrail to use the key
resource "aws_kms_key_policy" "remediation_cloudtrail_logs_kms_key_policy" {

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
  key_id = aws_kms_key.remediation_cloudtrail_logs_kms_key.key_id
}

# Attach the KMS key to the CloudTrail configuration
resource "aws_cloudtrail" "remediation_cloudtrail_1" {
  name           = "remediation-cloudtrail"
  s3_bucket_name = aws_s3_bucket.remediation_cloudtrail_logs.id
  # ... (existing configuration)
  kms_key_id = aws_kms_key.remediation_cloudtrail_logs_kms_key.id
}

# Attach the KMS key to the S3 bucket server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "remediation_cloudtrail_logs_encryption" {
  bucket = aws_s3_bucket.remediation_cloudtrail_logs.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.remediation_cloudtrail_logs_kms_key.id
      sse_algorithm     = "aws:kms"
    }
  }
}

variable "s3_bucket_name" {
  description = "Target S3 bucket name for remediation"
  type        = string
  default     = "aws-cloudtrail-logs-132410971304-0971c04b"
}
