# Enable server access logging for the S3 bucket
resource "aws_s3_bucket" "remediation_cloudtrail_logs" {
  bucket = var.s3_bucket_name

  logging {
    target_bucket = aws_s3_bucket.remediation_cloudtrail_logs_target.id
    target_prefix = "s3-access-logs/"
  }

}

# Create a dedicated log bucket for storing the S3 access logs
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

# Create an SNS topic to receive security notifications
resource "aws_sns_topic" "remediation_security_notifications" {
  name = "remediation-security-notifications"
}

# Create an IAM policy to grant permissions to the SNS topic
data "aws_iam_policy_document" "remediation_security_notifications_policy" {
  statement {
    actions = [
      "sns:Publish",
    ]
    resources = [
      aws_sns_topic.remediation_security_notifications.arn,
    ]
    principals {
      type        = "Service"
      identifiers = ["cloudwatch.amazonaws.com"]
    }
  }
}

resource "aws_sns_topic_policy" "remediation_security_notifications_policy" {
  policy = data.aws_iam_policy_document.remediation_security_notifications_policy.json
  arn    = aws_sns_topic.remediation_security_notifications.arn
}

# Create a CloudWatch alarm to monitor the S3 bucket for security events
resource "aws_cloudwatch_metric_alarm" "remediation_s3_bucket_security_alarm" {
  alarm_name          = "remediation-s3-bucket-security-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "NumberOfObjects"
  namespace           = "AWS/S3"
  period              = 86400
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Alarm when new objects are added to the S3 bucket"
  alarm_actions       = [aws_sns_topic.remediation_security_notifications.arn]

  dimensions = {
    BucketName  = var.s3_bucket_name
    StorageType = "AllStorageTypes"
  }
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket to enable server access logging for"
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
