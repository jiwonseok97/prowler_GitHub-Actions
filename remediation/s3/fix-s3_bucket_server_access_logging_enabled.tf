# Enable server access logging for the S3 bucket
resource "aws_s3_bucket" "remediation_cloudtrail_logs" {
  bucket = var.s3_bucket_name


  logging {
    target_bucket = aws_s3_bucket.remediation_cloudtrail_logs_target.id
    target_prefix = "s3-access-logs/"
  }
}

# Create a dedicated S3 bucket to store the server access logs
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

# Create an SNS topic to receive security alerts
resource "aws_sns_topic" "remediation_security_alerts" {
  name = "remediation-security-alerts"
}

# Create an IAM policy to allow CloudTrail to publish logs to the SNS topic
data "aws_iam_policy_document" "remediation_cloudtrail_sns_policy" {
  statement {
    actions = [
      "sns:Publish",
    ]
    resources = [
      aws_sns_topic.remediation_security_alerts.arn,
    ]
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
  }
}

resource "aws_sns_topic_policy" "remediation_cloudtrail_sns_policy" {
  policy = data.aws_iam_policy_document.remediation_cloudtrail_sns_policy.json
  arn    = aws_sns_topic.remediation_security_alerts.arn
}

# Create an SNS subscription to receive security alerts
resource "aws_sns_topic_subscription" "remediation_security_alerts_subscription" {
  topic_arn = aws_sns_topic.remediation_security_alerts.arn
  protocol  = "email"
  endpoint  = var.security_alerts_email
}

# Create a KMS key to encrypt the CloudTrail logs
resource "aws_kms_key" "remediation_cloudtrail_logs_key" {
  description             = "CloudTrail Logs Encryption Key"
  deletion_window_in_days = 10
}

# Apply the KMS key to the CloudTrail logs bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "remediation_cloudtrail_logs_encryption" {
  bucket = aws_s3_bucket.remediation_cloudtrail_logs.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.remediation_cloudtrail_logs_key.id
      sse_algorithm     = "aws:kms"
    }
  }
}

variable "s3_bucket_name" {
  description = "Target S3 bucket name for remediation"
  type        = string
  default     = "aws-cloudtrail-logs-132410971304-0971c04b"
}


variable "security_alerts_email" {
  description = "security_alerts_email"
  type        = string
  default     = ""
}
