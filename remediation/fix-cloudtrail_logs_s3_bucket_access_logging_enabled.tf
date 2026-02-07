# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Get the existing CloudTrail trail
data "aws_cloudtrail_service_account" "current" {}

# Create a new S3 bucket for CloudTrail log access logging
resource "aws_s3_bucket" "cloudtrail_logs_access_logging" {
  bucket = "cloudtrail-logs-access-logging"
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

# Enable S3 server access logging on the CloudTrail logs bucket
resource "aws_s3_bucket_logging" "cloudtrail_logs_bucket_logging" {
  bucket        = "security-cloudtail"
  target_bucket = aws_s3_bucket.cloudtrail_logs_access_logging.id
  target_prefix = "cloudtrail-logs-access-logging/"
}

# Grant the CloudTrail service account the necessary permissions to write logs to the access logging bucket
resource "aws_s3_bucket_policy" "cloudtrail_logs_access_logging_policy" {
  bucket = aws_s3_bucket.cloudtrail_logs_access_logging.id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "${data.aws_cloudtrail_service_account.current.id}"
      },
      "Action": "s3:PutObject",
      "Resource": "${aws_s3_bucket.cloudtrail_logs_access_logging.arn}/*"
    }
  ]
}
POLICY
}


This Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Retrieves the existing CloudTrail service account using the `aws_cloudtrail_service_account` data source.
3. Creates a new S3 bucket named `cloudtrail-logs-access-logging` for storing the CloudTrail log access logs. This bucket has versioning and server-side encryption enabled.
4. Enables S3 server access logging on the existing CloudTrail logs bucket (`security-cloudtail`) and configures the access logging bucket as the target.
5. Grants the CloudTrail service account the necessary permissions to write logs to the access logging bucket.