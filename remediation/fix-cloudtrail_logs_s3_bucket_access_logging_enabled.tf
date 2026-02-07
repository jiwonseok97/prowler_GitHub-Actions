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
  depends_on = [aws_s3_bucket_ownership_controls.cloudtrail_logs_bucket]
  bucket = aws_s3_bucket.cloudtrail_logs_bucket.id
  acl    = "private"
}

resource "aws_s3_bucket_logging" "cloudtrail_logs_bucket" {
  bucket        = aws_s3_bucket.cloudtrail_logs_bucket.id
  target_bucket = aws_s3_bucket.cloudtrail_logs_bucket.id
  target_prefix = "logs/"
}

# Grant the CloudTrail service account the necessary permissions to write logs to the new bucket
resource "aws_s3_bucket_policy" "cloudtrail_logs_bucket" {
  bucket = aws_s3_bucket.cloudtrail_logs_bucket.id
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
      "Resource": "${aws_s3_bucket.cloudtrail_logs_bucket.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
    },
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "delivery.logs.amazonaws.com"
      },
      "Action": "s3:PutObject",
      "Resource": "${aws_s3_bucket.cloudtrail_logs_bucket.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*",
      "Condition": {
        "StringEquals": {
          "s3:x-amz-acl": "bucket-owner-full-control"
        }
      }
    },
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "delivery.logs.amazonaws.com"
      },
      "Action": "s3:GetBucketAcl",
      "Resource": "${aws_s3_bucket.cloudtrail_logs_bucket.arn}"
    }
  ]
}
POLICY
}

# Get the current AWS account ID
data "aws_caller_identity" "current" {}


This Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Retrieves the existing CloudTrail service account using the `aws_cloudtrail_service_account` data source.
3. Creates a new S3 bucket for CloudTrail access logs, with versioning and server-side encryption enabled.
4. Enables S3 server access logging on the CloudTrail logs bucket.
5. Grants the CloudTrail service account the necessary permissions to write logs to the new bucket.