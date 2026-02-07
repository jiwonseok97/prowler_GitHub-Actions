# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Get the existing S3 bucket resource
data "aws_s3_bucket" "aws_cloudtrail_logs" {
  bucket = "aws-cloudtrail-logs-132410971304-0971c04b"
}

# Enable default server-side encryption (SSE) on the S3 bucket using KMS
resource "aws_s3_bucket_ownership_controls" "aws_cloudtrail_logs" {
  bucket = data.aws_s3_bucket.aws_cloudtrail_logs.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "aws_cloudtrail_logs" {
  bucket = data.aws_s3_bucket.aws_cloudtrail_logs.id
  block_public_acls       = true
  block_public_policy    = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "aws_cloudtrail_logs" {
  bucket = data.aws_s3_bucket.aws_cloudtrail_logs.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}


The provided Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Retrieves the existing S3 bucket resource using the `data.aws_s3_bucket` data source.
3. Enables default server-side encryption (SSE) on the S3 bucket using KMS with the `aws_s3_bucket_server_side_encryption_configuration` resource.
4. Configures the bucket ownership controls and public access block settings using the `aws_s3_bucket_ownership_controls` and `aws_s3_bucket_public_access_block` resources, respectively.

This code addresses the security finding by enabling default encryption on the S3 bucket using KMS, which provides key control and auditing capabilities. It also applies the recommended "least privilege" and "defense in depth" principles by configuring the bucket ownership and public access settings.