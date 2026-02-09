# Enable S3 server access logging for the CloudTrail logs bucket
resource "aws_s3_bucket" "remediation_cloudtrail_logs_bucket_logging" {
  bucket = "remediation-cloudtrail-logs-bucket-logging"
  acl    = "private"

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

# Update the existing CloudTrail trail to log to the new logging bucket
resource "aws_cloudtrail" "remediation_security_cloudtrail" {
  name                          = "security-cloudtail"
  s3_bucket_name                = "remediation-cloudtrail-logs-bucket"
  s3_key_prefix                 = "cloudtrail-logs"
  is_multi_region_trail         = true
  include_global_service_events = true


  cloud_watch_logs_group_arn = aws_cloudwatch_log_group.remediation_cloudtrail_logs.arn
  cloud_watch_logs_role_arn   = aws_iam_role.remediation_cloudtrail_cloudwatch_role.arn

  depends_on = [
    aws_s3_bucket.remediation_cloudtrail_logs_bucket_logging,
    aws_iam_role_policy.remediation_cloudtrail_cloudwatch_policy
  ]
}

# Create a CloudWatch log group for CloudTrail logs
resource "aws_cloudwatch_log_group" "remediation_cloudtrail_logs" {
  name = "remediation-cloudtrail-logs"
}

# Create an IAM role for CloudTrail to publish logs to CloudWatch
resource "aws_iam_role" "remediation_cloudtrail_cloudwatch_role" {
  name = "remediation-cloudtrail-cloudwatch-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
      }
    ]
  })
}

# Attach the required policy to the CloudTrail CloudWatch role
resource "aws_iam_role_policy" "remediation_cloudtrail_cloudwatch_policy" {
  name = "remediation-cloudtrail-cloudwatch-policy"
  role = aws_iam_role.remediation_cloudtrail_cloudwatch_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ],
        Resource = aws_cloudwatch_log_group.remediation_cloudtrail_logs.arn
      }
    ]
  })
}