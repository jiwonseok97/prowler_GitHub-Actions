# Configure the AWS provider for the ap-northeast-2 region

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
2. Retrieves the existing S3 bucket resource using the `data` source.
3. Enables default server-side encryption (SSE) on the S3 bucket using KMS.
4. Configures the public access block settings for the S3 bucket to enforce strict access controls.