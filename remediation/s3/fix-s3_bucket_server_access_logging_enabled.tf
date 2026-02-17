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
  description             = "KMS key for CloudTrail logs encryption"
  deletion_window_in_days = 30
}

resource "aws_kms_alias" "remediation_cloudtrail_logs_kms_key_alias" {
  name          = "alias/alias-remediation-cloudtrail-logs-kms-key"
  target_key_id = aws_kms_key.remediation_cloudtrail_logs_kms_key.id
}

# Apply the KMS key policy to allow CloudTrail to use the key
resource "aws_kms_key_policy" "remediation_cloudtrail_logs_kms_key_policy" {

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        },
        Action   = "kms:GenerateDataKey*",
        Resource = "*"
      },
      {
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
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

# Apply the S3 bucket policy to allow CloudTrail to write logs
resource "aws_s3_bucket_policy" "remediation_cloudtrail_logs_bucket_policy" {
  bucket = aws_s3_bucket.remediation_cloudtrail_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        },
        Action   = "s3:GetBucketAcl",
        Resource = "arn:aws:s3:::${var.s3_bucket_name}"
      },
      {
        Effect = "Allow",
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        },
        Action   = "s3:PutObject",
        Resource = "arn:aws:s3:::${var.s3_bucket_name}/cloudtrail/AWSLogs/${data.aws_caller_identity.current.account_id}/*",
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

variable "s3_bucket_name" {
  description = "Target S3 bucket name for remediation"
  type        = string
  default     = "aws-cloudtrail-logs-132410971304-0971c04b"
}


variable "cloudtrail_logs_notification_email" {
  description = "cloudtrail_logs_notification_email"
  type        = string
  default     = ""
}
