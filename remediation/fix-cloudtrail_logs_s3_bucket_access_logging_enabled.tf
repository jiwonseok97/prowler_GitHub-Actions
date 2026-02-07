# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Get the existing CloudTrail trail
data "aws_cloudtrail" "security_cloudtrail" {
  name = "security-cloudtail"
}

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
  bucket        = data.aws_cloudtrail.security_cloudtrail.s3_bucket_name
  target_bucket = aws_s3_bucket.cloudtrail_logs_access_logging.id
  target_prefix = "cloudtrail-logs-access-logging/"
}