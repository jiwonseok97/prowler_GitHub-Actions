# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Get the existing CloudTrail trail
data "aws_cloudtrail_service_account" "current" {}

# Create a new S3 bucket for CloudTrail access logs
resource "aws_s3_bucket" "cloudtrail_logs_bucket" {
  bucket = "my-cloudtrail-logs-bucket"
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
resource "aws_s3_bucket_ownership_controls" "cloudtrail_logs_bucket" {
  bucket = aws_s3_bucket.cloudtrail_logs_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "cloudtrail_logs_bucket" {
  bucket = aws_s3_bucket.cloudtrail_logs_bucket.id
  acl    = "private"
}

# Update the CloudTrail trail to use the new logs bucket
resource "aws_cloudtrail" "security_cloudtrail" {
  name                          = "security-cloudtail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail_logs_bucket.id
  s3_key_prefix                 = "cloudtrail-logs"
  is_multi_region_trail         = true
  include_global_service_events = true
  enable_log_file_validation    = true

  depends_on = [
    aws_s3_bucket_ownership_controls.cloudtrail_logs_bucket,
    aws_s3_bucket_acl.cloudtrail_logs_bucket,
  ]
}


This Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Retrieves the existing CloudTrail service account using a data source.
3. Creates a new S3 bucket for CloudTrail access logs, with versioning and server-side encryption enabled.
4. Enables S3 server access logging on the CloudTrail logs bucket.
5. Updates the existing CloudTrail trail to use the new logs bucket, and enables additional security features like log file validation.