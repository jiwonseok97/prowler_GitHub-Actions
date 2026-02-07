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
3. Enables default server-side encryption (SSE) on the S3 bucket using KMS by creating the `aws_s3_bucket_ownership_controls` and `aws_s3_bucket_server_side_encryption_configuration` resources.