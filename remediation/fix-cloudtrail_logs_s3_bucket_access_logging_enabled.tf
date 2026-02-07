# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Get the existing CloudTrail trail
data "aws_cloudtrail_service_account" "current" {}

# Create a new S3 bucket for access logging
resource "aws_s3_bucket" "cloudtrail_logs_bucket_access_logging" {
  bucket = "cloudtrail-logs-bucket-access-logging"
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

# Enable access logging on the CloudTrail logs bucket
resource "aws_s3_bucket_logging" "cloudtrail_logs_bucket_access_logging" {
  target_bucket = aws_s3_bucket.cloudtrail_logs_bucket_access_logging.id
  target_prefix = "cloudtrail-logs-bucket-access-logs/"
}

# Grant the CloudTrail service account the necessary permissions to write logs to the access logging bucket
resource "aws_s3_bucket_policy" "cloudtrail_logs_bucket_access_logging" {
  bucket = aws_s3_bucket.cloudtrail_logs_bucket_access_logging.id

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
      "Resource": "${aws_s3_bucket.cloudtrail_logs_bucket_access_logging.arn}/*"
    }
  ]
}
POLICY
}


This Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Retrieves the CloudTrail service account ID using the `aws_cloudtrail_service_account` data source.
3. Creates a new S3 bucket for access logging, with versioning and server-side encryption enabled.
4. Enables access logging on the existing CloudTrail logs bucket, using the newly created access logging bucket.
5. Grants the CloudTrail service account the necessary permissions to write logs to the access logging bucket.