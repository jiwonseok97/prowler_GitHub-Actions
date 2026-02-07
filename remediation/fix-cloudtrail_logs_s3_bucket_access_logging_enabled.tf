# Configure the AWS provider for the ap-northeast-2 region

# Get the existing CloudTrail trail
data "aws_cloudtrail_service_account" "current" {}

# Create a new S3 bucket for CloudTrail log access logging
resource "aws_s3_bucket" "cloudtrail_logs_access_logging" {
  bucket = "cloudtrail-logs-access-logging"
  acl    = "private"

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

# Enable S3 server access logging on the CloudTrail logs bucket
resource "aws_s3_bucket_ownership_controls" "cloudtrail_logs" {
  bucket = "security-cloudtail"
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "cloudtrail_logs" {
  depends_on = [aws_s3_bucket_ownership_controls.cloudtrail_logs]
  bucket = "security-cloudtail"
  acl    = "private"
}

resource "aws_s3_bucket_logging" "cloudtrail_logs" {
  bucket        = "security-cloudtail"
  target_bucket = aws_s3_bucket.cloudtrail_logs_access_logging.id
  target_prefix = "cloudtrail-logs-access-logging/"
}


The provided Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Retrieves the current AWS CloudTrail service account using the `aws_cloudtrail_service_account` data source.
3. Creates a new S3 bucket named `cloudtrail-logs-access-logging` for storing the CloudTrail log access logs. This bucket has versioning and server-side encryption enabled.
4. Enables S3 server access logging on the existing CloudTrail logs bucket (`security-cloudtail`) by:
   - Setting the bucket ownership controls to `BucketOwnerPreferred`.
   - Setting the bucket ACL to `private`.
   - Configuring the bucket logging to write the access logs to the `cloudtrail-logs-access-logging` bucket.

# This Terraform code should address the security finding by enabling S3 server access logging on the CloudTrail logs bucket and writing the logs to a separate, tightly controlled bucket.