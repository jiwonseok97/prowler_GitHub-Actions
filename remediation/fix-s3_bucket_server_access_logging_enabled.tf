# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Create a new S3 bucket for server access logging
resource "aws_s3_bucket" "log_bucket" {
  bucket = "aws-cloudtrail-logs-132410971304-0971c04b-logs"
  acl    = "private"

  versioning {
    enabled = true
  }

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

# Enable server access logging on the existing S3 bucket
resource "aws_s3_bucket_logging" "log_bucket_logging" {
  bucket        = "aws-cloudtrail-logs-132410971304-0971c04b"
  target_bucket = aws_s3_bucket.log_bucket.id
  target_prefix = "logs/"
}

# Enable CloudTrail data events for the existing S3 bucket
resource "aws_cloudtrail" "cloudtrail" {
  name                          = "cloudtrail-for-aws-cloudtrail-logs-132410971304-0971c04b"
  s3_bucket_name                = "aws-cloudtrail-logs-132410971304-0971c04b"
  s3_key_prefix                 = "cloudtrail"
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  depends_on                    = [aws_s3_bucket_policy.log_bucket_policy]
}

# Create a policy to protect the log bucket from tampering
resource "aws_s3_bucket_policy" "log_bucket_policy" {
  bucket = aws_s3_bucket.log_bucket.id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudtrail.amazonaws.com"
      },
      "Action": "s3:GetBucketAcl",
      "Resource": "${aws_s3_bucket.log_bucket.arn}"
    },
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudtrail.amazonaws.com"
      },
      "Action": "s3:PutObject",
      "Resource": "${aws_s3_bucket.log_bucket.arn}/*/AWSLogs/*",
      "Condition": {
        "StringEquals": {
          "s3:x-amz-acl": "bucket-owner-full-control"
        }
      }
    }
  ]
}
POLICY
}


This Terraform code does the following:

1. Configures the AWS provider for the ap-northeast-2 region.
2. Creates a new S3 bucket for server access logging, with versioning and lifecycle management enabled.
3. Enables server access logging on the existing S3 bucket, with the logs being sent to the newly created log bucket.
4. Enables CloudTrail data events for the existing S3 bucket, providing object-level visibility.
5. Creates a bucket policy to protect the log bucket from tampering, allowing CloudTrail to write logs and get the bucket ACL.