# Enable default SSE-KMS encryption for the S3 bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "remediation_s3_bucket_encryption" {
  bucket = var.s3_bucket_name

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.remediation_s3_bucket_key.arn
    }
  }
}

# Create a customer-managed KMS key for the S3 bucket
resource "aws_kms_key" "remediation_s3_bucket_key" {
  description             = "Customer managed key for S3 bucket encryption"
  deletion_window_in_days = 30
  enable_key_rotation     = true
}

# Attach a bucket policy to enforce KMS encryption
data "aws_iam_policy_document" "remediation_s3_bucket_policy" {
  statement {
    sid       = "DenyUnencryptedObjectUploads"
    effect    = "Deny"
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.remediation_s3_bucket.arn}/*"]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    condition {
      test     = "StringNotEquals"
      variable = "s3:x-amz-server-side-encryption"
      values   = ["aws:kms"]
    }
  }
}

resource "aws_s3_bucket_policy" "remediation_s3_bucket_policy" {
  bucket = aws_s3_bucket.remediation_s3_bucket.id
  policy = data.aws_iam_policy_document.remediation_s3_bucket_policy.json
}

# Create the S3 bucket with the required encryption
resource "aws_s3_bucket" "remediation_s3_bucket" {
  bucket = var.s3_bucket_name
}

# Attach the required IAM permissions for the KMS key
resource "aws_kms_key_policy" "remediation_s3_bucket_key_policy" {
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        Action   = "kms:*",
        Resource = "*"
      },
      {
        Effect = "Allow",
        Principal = {
          Service = "logs.${data.aws_region.current.name}.amazonaws.com"
        },
        Action = [
          "kms:Encrypt*",
          "kms:Decrypt*",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:Describe*"
        ],
        Resource = "*"
      }
    ]
  })
  key_id = aws_kms_key.remediation_s3_bucket_key.key_id
}

# Create an SNS topic to receive CloudTrail notifications
resource "aws_sns_topic" "remediation_cloudtrail_notifications" {
  name = "remediation-cloudtrail-notifications"
}

# Attach a policy to the SNS topic to allow CloudTrail to publish messages
resource "aws_sns_topic_policy" "remediation_cloudtrail_notifications_policy" {
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        },
        Action   = "sns:Publish",
        Resource = aws_sns_topic.remediation_cloudtrail_notifications.arn
      }
    ]
  })
  arn = aws_sns_topic.remediation_cloudtrail_notifications.arn
}

# Create a CloudTrail trail to monitor the S3 bucket and KMS key activity
resource "aws_cloudtrail" "remediation_cloudtrail" {
  name                          = "remediation-cloudtrail"
  s3_bucket_name                = aws_s3_bucket.remediation_s3_bucket.id
  s3_key_prefix                 = "cloudtrail-logs"
  is_multi_region_trail         = true
  include_global_service_events = true
  enable_log_file_validation    = true
  kms_key_id                    = aws_kms_key.remediation_s3_bucket_key.arn
  sns_topic_name                = aws_sns_topic.remediation_cloudtrail_notifications.name
}

# Use input variables for the S3 bucket name and other required values
variable "s3_bucket_name" {
  description = "Name of the S3 bucket to be encrypted"
  type        = string
  default     = "aws-cloudtrail-logs-132410971304-0971c04b"
}
