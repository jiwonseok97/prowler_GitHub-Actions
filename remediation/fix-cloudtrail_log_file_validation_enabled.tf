# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Get the existing CloudTrail trail
data "aws_cloudtrail_service_account" "current" {}

data "aws_cloudtrail" "security_cloudtrail" {
  name = "security-cloudtail"
}

# Enable log file validation on the existing CloudTrail trail
resource "aws_cloudtrail" "security_cloudtrail" {
  name                          = data.aws_cloudtrail.security_cloudtrail.name
  s3_bucket_name                = data.aws_cloudtrail.security_cloudtrail.s3_bucket_name
  s3_key_prefix                 = data.aws_cloudtrail.security_cloudtrail.s3_key_prefix
  is_multi_region_trail         = data.aws_cloudtrail.security_cloudtrail.is_multi_region_trail
  include_global_service_events = data.aws_cloudtrail.security_cloudtrail.include_global_service_events
  is_organization_trail         = data.aws_cloudtrail.security_cloudtrail.is_organization_trail
  kms_key_id                    = data.aws_cloudtrail.security_cloudtrail.kms_key_id
  log_file_validation_enabled   = true # Enable log file validation
}

# Enforce least privilege on the logs bucket
resource "aws_s3_bucket_ownership_controls" "logs_bucket" {
  bucket = data.aws_cloudtrail.security_cloudtrail.s3_bucket_name
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "logs_bucket" {
  bucket = data.aws_cloudtrail.security_cloudtrail.s3_bucket_name
  acl    = "private"
}

# Retain and protect digest files
resource "aws_s3_bucket_object_lock_configuration" "logs_bucket" {
  bucket = data.aws_cloudtrail.security_cloudtrail.s3_bucket_name
  rule {
    default_retention {
      mode = "COMPLIANCE"
      days = 90
    }
  }
}

resource "aws_s3_bucket_versioning" "logs_bucket" {
  bucket = data.aws_cloudtrail.security_cloudtrail.s3_bucket_name
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "logs_bucket" {
  bucket = data.aws_cloudtrail.security_cloudtrail.s3_bucket_name
  block_public_acls       = true
  block_public_policy    = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


This Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Retrieves the existing CloudTrail trail named `security-cloudtail` using the `data.aws_cloudtrail` data source.
3. Enables log file validation on the existing CloudTrail trail using the `aws_cloudtrail` resource.
4. Enforces least privilege on the logs bucket by setting the bucket ownership controls and ACL to `private`.
5. Retains and protects the digest files by configuring the S3 bucket object lock configuration and versioning.
6. Blocks public access to the logs bucket using the `aws_s3_bucket_public_access_block` resource.