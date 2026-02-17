# Enable default server-side encryption (SSE) on the existing S3 bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "remediation_s3_bucket_encryption" {
  bucket = "aws-cloudtrail-logs-132410971304-0971c04b"

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Attach the required KMS key policy to the existing KMS key
resource "aws_kms_key_policy" "remediation_kms_key_policy" {

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
      }
    ]
  })
  key_id = aws_kms_key.remediation_kms_key.key_id
}

# Attach the required IAM policy to the existing IAM user

# Attach the required IAM policy to the existing IAM role

# Create an SNS topic and attach the required policy
resource "aws_sns_topic" "remediation_sns_topic" {
  name = "remediation-cloudtrail-logs-topic"
}

resource "aws_sns_topic_policy" "remediation_sns_topic_policy" {

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          AWS = "*"
        },
        Action   = "sns:Publish",
        Resource = aws_sns_topic.remediation_sns_topic.arn
      }
    ]
  })
  arn = aws_sns_topic.remediation_sns_topic.arn
}

# Create a KMS key and attach the required policy
resource "aws_kms_key" "remediation_kms_key" {
  description             = "Remediation CloudTrail Logs KMS Key"
  deletion_window_in_days = 10
}

resource "aws_kms_key_policy" "remediation_kms_key_policy_2" {

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
      }
    ]
  })
  key_id = aws_kms_key.remediation_kms_key.key_id
}
