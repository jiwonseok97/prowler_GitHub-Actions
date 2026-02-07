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
resource "aws_s3_bucket_policy" "cloudtrail_logs_bucket_policy" {
  bucket = "my-cloudtrail-logs-bucket"
  policy = data.aws_iam_policy_document.cloudtrail_logs_bucket_policy_document.json
}

data "aws_iam_policy_document" "cloudtrail_logs_bucket_policy_document" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions = [
      "s3:GetBucketAcl",
      "s3:GetBucketPolicy",
      "s3:ListBucket",
      "s3:PutObject",
    ]
    resources = [
      "arn:aws:s3:::my-cloudtrail-logs-bucket",
      "arn:aws:s3:::my-cloudtrail-logs-bucket/*",
    ]
  }
}

# Retain and protect digest files
resource "aws_s3_bucket_object_lock_configuration" "cloudtrail_logs_bucket_object_lock_configuration" {
  bucket = "my-cloudtrail-logs-bucket"
  rule {
    default_retention {
      mode = "COMPLIANCE"
      days = 90
    }
  }
}

resource "aws_s3_bucket_ownership_controls" "cloudtrail_logs_bucket_ownership_controls" {
  bucket = "my-cloudtrail-logs-bucket"
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "cloudtrail_logs_bucket_public_access_block" {
  bucket = "my-cloudtrail-logs-bucket"
  block_public_acls       = true
  block_public_policy    = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


The provided Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Retrieves the existing CloudTrail service account using the `aws_cloudtrail_service_account` data source.
3. Creates a new CloudTrail trail named `security-cloudtail` with the following configurations:
   - Enables log file integrity validation (`enable_log_file_validation = true`).
   - Sets the S3 bucket name and prefix for storing the CloudTrail logs.
   - Enables multi-region trail and global service event logging.
4. Enforces least privilege on the CloudTrail logs bucket by creating an S3 bucket policy that allows the necessary actions for CloudTrail.
5. Retains and protects the digest files by:
   - Enabling S3 Object Lock with a 90-day compliance mode retention period.
   - Setting the bucket ownership controls to "BucketOwnerPreferred".
   - Enabling public access blocking on the bucket.