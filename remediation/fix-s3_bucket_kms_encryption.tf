# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Get the existing S3 bucket resource
data "aws_s3_bucket" "aws_cloudtrail_logs" {
  bucket = "aws-cloudtrail-logs-132410971304-0971c04b"
}

# Enable default server-side encryption with a customer-managed KMS key
resource "aws_s3_bucket_ownership_controls" "aws_cloudtrail_logs" {
  bucket = data.aws_s3_bucket.aws_cloudtrail_logs.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "aws_cloudtrail_logs" {
  bucket = data.aws_s3_bucket.aws_cloudtrail_logs.id
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.aws_cloudtrail_logs_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

# Create a customer-managed KMS key for the S3 bucket
resource "aws_kms_key" "aws_cloudtrail_logs_key" {
  description             = "Customer-managed KMS key for aws-cloudtrail-logs-132410971304-0971c04b"
  deletion_window_in_days = 30
  enable_key_rotation     = true
}

# Attach a bucket policy to enforce KMS encryption
resource "aws_s3_bucket_policy" "aws_cloudtrail_logs" {
  bucket = data.aws_s3_bucket.aws_cloudtrail_logs.id
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Deny",
            "Principal": "*",
            "Action": "s3:PutObject",
            "Resource": "${data.aws_s3_bucket.aws_cloudtrail_logs.arn}/*",
            "Condition": {
                "StringNotEquals": {
                    "s3:x-amz-server-side-encryption": "aws:kms"
                }
            }
        }
    ]
}
POLICY
}


This Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Retrieves the existing S3 bucket resource using the `aws_s3_bucket` data source.
3. Enables default server-side encryption with a customer-managed KMS key for the S3 bucket.
4. Creates a customer-managed KMS key for the S3 bucket.
5. Attaches a bucket policy to the S3 bucket to enforce KMS encryption for all objects uploaded to the bucket.