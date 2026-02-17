resource "aws_s3_bucket" "remediation_cloudtrail_logs" {
  bucket = var.s3_bucket_name

  logging {
    target_bucket = aws_s3_bucket.remediation_cloudtrail_logs_destination.id
    target_prefix = "s3-access-logs/"
  }
}

resource "aws_s3_bucket" "remediation_cloudtrail_logs_destination" {
  bucket = "remediation-cloudtrail-logs-${data.aws_caller_identity.current.account_id}"
}


resource "aws_cloudtrail" "remediation_cloudtrail" {
  name                          = "remediation-cloudtrail-data.aws_caller_identity.current.account_id"
  s3_bucket_name                = var.s3_bucket_name
  s3_key_prefix                 = "cloudtrail"
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  kms_key_id                    = aws_kms_key.remediation_cloudtrail_logs_kms_key.arn
  sns_topic_name                = aws_sns_topic.remediation_cloudtrail_logs_notification.name

  event_selector {
    read_write_type           = "All"
    include_management_events = true

    data_resource {
      type   = "AWS::S3::Object"
      values = ["arn:${data.aws_partition.current.partition}:s3:::${var.s3_bucket_name}/"]
    }
  }
}

resource "aws_sns_topic" "remediation_cloudtrail_logs_notification" {
  name = "remediation-cloudtrail-logs-notification-data.aws_caller_identity.current.account_id"
}

resource "aws_sns_topic_policy" "remediation_cloudtrail_logs_notification_policy" {
  policy = data.aws_iam_policy_document.remediation_cloudtrail_logs_notification_policy.json
  arn    = aws_sns_topic.remediation_cloudtrail_logs_notification.arn
}

data "aws_iam_policy_document" "remediation_cloudtrail_logs_notification_policy" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions   = ["SNS:Publish"]
    resources = [aws_sns_topic.remediation_cloudtrail_logs_notification.arn]
  }
}

resource "aws_kms_key" "remediation_cloudtrail_logs_kms_key" {
  description             = "KMS key for CloudTrail logs encryption"
  deletion_window_in_days = 30
}

resource "aws_kms_key_policy" "remediation_cloudtrail_logs_kms_key_policy" {
  policy = data.aws_iam_policy_document.remediation_cloudtrail_logs_kms_key_policy.json
  key_id = aws_kms_key.remediation_cloudtrail_logs_kms_key.key_id
}

data "aws_iam_policy_document" "remediation_cloudtrail_logs_kms_key_policy" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions   = ["kms:GenerateDataKey*"]
    resources = ["*"]
  }
  statement {
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
    ]
    resources = ["*"]
  }
}

variable "s3_bucket_name" {
  description = "Target S3 bucket name for remediation"
  type        = string
  default     = "aws-cloudtrail-logs-132410971304-0971c04b"
}
