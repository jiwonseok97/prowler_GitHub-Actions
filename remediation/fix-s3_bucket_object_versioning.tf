# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Get the existing S3 bucket resource
data "aws_s3_bucket" "aws_cloudtrail_logs" {
  bucket = "aws-cloudtrail-logs-132410971304-0971c04b"
}

# Enable S3 versioning for the existing bucket
resource "aws_s3_bucket_versioning" "aws_cloudtrail_logs_versioning" {
  bucket = data.aws_s3_bucket.aws_cloudtrail_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Apply lifecycle rules to manage noncurrent versions and costs
resource "aws_s3_bucket_lifecycle_configuration" "aws_cloudtrail_logs_lifecycle" {
  bucket = data.aws_s3_bucket.aws_cloudtrail_logs.id

  rule {
    id     = "NoncurrentVersionExpiration"
    status = "Enabled"

    noncurrent_version_expiration {
      days = 30
    }
  }
}


The provided Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Retrieves the existing S3 bucket resource using the `data` source.
3. Enables S3 versioning for the existing bucket using the `aws_s3_bucket_versioning` resource.
4. Applies lifecycle rules to manage noncurrent versions and costs using the `aws_s3_bucket_lifecycle_configuration` resource.