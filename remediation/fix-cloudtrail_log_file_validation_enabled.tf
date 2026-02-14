# Enable log file validation on the existing CloudTrail trail
resource "aws_cloudtrail" "remediation_security_cloudtail" {
  name = "security-cloudtail"
  s3_bucket_name                = data.aws_s3_bucket.remediation_security_cloudtrail_logs.id
  s3_key_prefix                 = "cloudtrail-logs"
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  depends_on                    = [data.aws_s3_bucket.remediation_security_cloudtrail_logs]
}

# Reference the existing S3 bucket for CloudTrail logs
data "aws_s3_bucket" "remediation_security_cloudtrail_logs" {
  bucket = "security-cloudtrail-logs"
}

# Enforce least privilege on the CloudTrail logs bucket

resource "aws_s3_bucket_server_side_encryption_configuration" "remediation_security_cloudtrail_logs_encryption" {
  bucket = data.aws_s3_bucket.remediation_security_cloudtrail_logs.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Retain and protect digest files using S3 Object Lock
resource "aws_s3_bucket_object_lock_configuration" "remediation_security_cloudtrail_logs_lock" {
  bucket = data.aws_s3_bucket.remediation_security_cloudtrail_logs.id
  rule {
    default_retention {
      mode = "COMPLIANCE"
      days = 90
    }
  }
}

# Monitor CloudTrail log file validation results using SNS
resource "aws_sns_topic" "remediation_cloudtrail_validation_alerts" {
  name = "cloudtrail-validation-alerts"
}

resource "aws_sns_topic_subscription" "remediation_cloudtrail_validation_alerts_subscription" {
  topic_arn = aws_sns_topic.remediation_cloudtrail_validation_alerts.arn
  protocol  = "email"
  endpoint  = var.notification_email
}

resource "aws_sns_topic_policy" "remediation_cloudtrail_validation_alerts_policy" {
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        },
        Action = "SNS:Publish",
        Resource = aws_sns_topic.remediation_cloudtrail_validation_alerts.arn
      }
    ]
  })
  arn = aws_sns_topic.remediation_cloudtrail_validation_alerts.arn
}

variable "notification_email" {
  description = "Email for alarm notifications"
  type        = string
  default     = "security@example.com"
}