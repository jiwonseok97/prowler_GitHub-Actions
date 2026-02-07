# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Get the existing S3 bucket resource
data "aws_s3_bucket" "aws_cloudtrail_logs" {
  bucket = "aws-cloudtrail-logs-132410971304-0971c04b"
}

# Enable MFA Delete on the S3 bucket
resource "aws_s3_bucket_ownership_controls" "aws_cloudtrail_logs" {
  bucket = data.aws_s3_bucket.aws_cloudtrail_logs.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_versioning" "aws_cloudtrail_logs" {
  bucket = data.aws_s3_bucket.aws_cloudtrail_logs.id
  versioning_configuration {
    status = "Enabled"
    mfa_delete = "Enabled"
  }
}


The provided Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Retrieves the existing S3 bucket resource using the `aws_s3_bucket` data source.
3. Enables MFA Delete on the S3 bucket by creating an `aws_s3_bucket_ownership_controls` resource and an `aws_s3_bucket_versioning` resource.

The `aws_s3_bucket_ownership_controls` resource sets the object ownership to "BucketOwnerPreferred", which is a requirement for enabling MFA Delete.

The `aws_s3_bucket_versioning` resource enables versioning and sets the `mfa_delete` option to "Enabled", which requires MFA authentication for permanent deletions and version changes.