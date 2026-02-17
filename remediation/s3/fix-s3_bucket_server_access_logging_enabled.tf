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

# Create an SNS topic to receive security notifications
resource "aws_sns_topic" "remediation_security_notifications" {
  name = "remediation-security-notifications"
}

# Create an IAM policy to allow CloudTrail to publish logs to the SNS topic
data "aws_iam_policy_document" "remediation_cloudtrail_sns_policy" {
  statement {
    actions = [
      "sns:Publish",
    ]
    resources = [
      aws_sns_topic.remediation_security_notifications.arn,
    ]
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
  }
}

resource "aws_sns_topic_policy" "remediation_cloudtrail_sns_policy" {
  policy = data.aws_iam_policy_document.remediation_cloudtrail_sns_policy.json
  arn    = aws_sns_topic.remediation_security_notifications.arn
}

# Create an IAM policy to allow CloudTrail to access the S3 bucket
data "aws_iam_policy_document" "remediation_cloudtrail_s3_policy" {
  statement {
    actions = [
      "s3:GetBucketAcl",
      "s3:GetBucketPolicy",
      "s3:ListBucket",
      "s3:PutObject",
    ]
    resources = [
      aws_s3_bucket.remediation_cloudtrail_logs.arn,
      "${aws_s3_bucket.remediation_cloudtrail_logs.arn}/*",
    ]
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
  }
}

resource "aws_s3_bucket_policy" "remediation_cloudtrail_s3_policy" {
  bucket = aws_s3_bucket.remediation_cloudtrail_logs.id
  policy = data.aws_iam_policy_document.remediation_cloudtrail_s3_policy.json
}

# Attach the CloudTrail managed policy to the CloudTrail role

# Attach the CloudTrail SNS policy to the CloudTrail role

# Attach the CloudTrail S3 policy to the CloudTrail role

variable "s3_bucket_name" {
  description = "Target S3 bucket name for remediation"
  type        = string
  default     = "aws-cloudtrail-logs-132410971304-0971c04b"
}
