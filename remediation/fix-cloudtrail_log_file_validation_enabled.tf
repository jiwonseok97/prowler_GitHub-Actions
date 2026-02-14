# Enable log file validation on the existing CloudTrail trail
resource "aws_cloudtrail" "remediation_security_cloudtail" {
  name = "security-cloudtail"
  s3_bucket_name                = data.aws_s3_bucket.remediation_security_cloudtrail_logs.id
  s3_key_prefix                 = "cloudtrail-logs"
  is_multi_region_trail         = true
  include_global_service_events = true
  enable_log_file_validation    = true
}

# Reference the existing S3 bucket for CloudTrail logs
data "aws_s3_bucket" "remediation_security_cloudtrail_logs" {
  bucket = "security-cloudtrail-logs"
}

# Ensure the S3 bucket has the appropriate access policy
resource "aws_s3_bucket_policy" "remediation_security_cloudtrail_logs_policy" {
  bucket = data.aws_s3_bucket.remediation_security_cloudtrail_logs.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        },
        Action = "s3:GetBucketAcl",
        Resource = "arn:aws:s3:::security-cloudtrail-logs"
      },
      {
        Effect = "Allow",
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        },
        Action = "s3:PutObject",
        Resource = "arn:aws:s3:::security-cloudtrail-logs/cloudtrail-logs/*",
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

# Enable S3 bucket versioning to protect the CloudTrail log files
resource "aws_s3_bucket_versioning" "remediation_security_cloudtrail_logs_versioning" {
  bucket = data.aws_s3_bucket.remediation_security_cloudtrail_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable S3 bucket encryption to protect the CloudTrail log files
resource "aws_s3_bucket_server_side_encryption_configuration" "remediation_security_cloudtrail_logs_encryption" {
  bucket = data.aws_s3_bucket.remediation_security_cloudtrail_logs.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}