# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Get the existing CloudTrail trail
data "aws_cloudtrail" "security_cloudtrail" {
  name = "security-cloudtail"
}

# Create a new S3 bucket for CloudTrail log storage
resource "aws_s3_bucket" "cloudtrail_logs" {
  bucket = "my-cloudtrail-logs"
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
resource "aws_s3_bucket_logging" "cloudtrail_logs_logging" {
  bucket        = aws_s3_bucket.cloudtrail_logs.id
  target_bucket = aws_s3_bucket.cloudtrail_logs.id
  target_prefix = "logs/"
}

# Update the CloudTrail trail to use the new S3 bucket
resource "aws_cloudtrail" "security_cloudtrail" {
  name                          = data.aws_cloudtrail.security_cloudtrail.name
  s3_bucket_name                = aws_s3_bucket.cloudtrail_logs.id
  s3_key_prefix                 = "cloudtrail"
  is_multi_region_trail         = true
  include_global_service_events = true
}


This Terraform code does the following:

1. Configures the AWS provider for the ap-northeast-2 region.
2. Retrieves the existing CloudTrail trail using the `data` source.
3. Creates a new S3 bucket for CloudTrail log storage, with versioning and server-side encryption enabled.
4. Enables S3 server access logging on the CloudTrail logs bucket, writing the logs to the same bucket.
5. Updates the existing CloudTrail trail to use the new S3 bucket for log storage.