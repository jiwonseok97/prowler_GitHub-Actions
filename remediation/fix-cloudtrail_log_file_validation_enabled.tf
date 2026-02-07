# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Get the existing CloudTrail trail
data "aws_cloudtrail_service_account" "current" {}

resource "aws_cloudtrail" "security_cloudtrail" {
  name                          = "security-cloudtail"
  s3_bucket_name                = "my-cloudtrail-logs-bucket"
  s3_key_prefix                 = "cloudtrail-logs"
  is_multi_region_trail         = true
  include_global_service_events = true
  enable_log_file_validation    = true # Enable log file integrity validation
}

# Enforce least privilege on the logs bucket
resource "aws_s3_bucket_ownership_controls" "logs_bucket" {
  bucket = "my-cloudtrail-logs-bucket"
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "logs_bucket" {
  bucket = "my-cloudtrail-logs-bucket"
  acl    = "private"
}

# Retain and protect digest files
resource "aws_s3_bucket_object_lock_configuration" "logs_bucket" {
  bucket = "my-cloudtrail-logs-bucket"
  rule {
    default_retention {
      mode = "COMPLIANCE"
      years = 7
    }
  }
}

resource "aws_s3_bucket_versioning" "logs_bucket" {
  bucket = "my-cloudtrail-logs-bucket"
  versioning_configuration {
    status = "Enabled"
  }
}


This Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Gets the existing CloudTrail service account using the `aws_cloudtrail_service_account` data source.
3. Creates a new CloudTrail trail named `security-cloudtail` with the following configurations:
   - Sets the S3 bucket name to `my-cloudtrail-logs-bucket`.
   - Sets the S3 key prefix to `cloudtrail-logs`.
   - Enables multi-region trail.
   - Includes global service events.
   - Enables log file integrity validation.
4. Enforces least privilege on the logs bucket by setting the bucket ownership controls and ACL to `private`.
5. Retains and protects the digest files by:
   - Enabling object lock configuration with a 7-year compliance mode retention.
   - Enabling bucket versioning.