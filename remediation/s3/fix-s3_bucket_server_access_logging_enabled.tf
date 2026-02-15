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

# Attach a bucket policy to the log target bucket to allow the CloudTrail bucket to write logs
resource "aws_s3_bucket_policy" "remediation_cloudtrail_logs_target_policy" {
  bucket = aws_s3_bucket.remediation_cloudtrail_logs_target.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        },
        Action   = "s3:PutObject",
        Resource = "${aws_s3_bucket.remediation_cloudtrail_logs_target.arn}/*"
      },
      {
        Effect = "Allow",
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        },
        Action   = "s3:GetBucketAcl",
        Resource = aws_s3_bucket.remediation_cloudtrail_logs_target.arn
      }
    ]
  })
}

variable "s3_bucket_name" {
  description = "Target S3 bucket name"
  type        = string
  default     = ""
}
