# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Create a new S3 bucket for server access logging
resource "aws_s3_bucket" "log_bucket" {
  bucket = "aws-cloudtrail-logs-132410971304-0971c04b-logs"
  acl    = "private"

  versioning {
    enabled = true
  }

  lifecycle_rule {
    enabled = true

    transition {
      days          = 30
      storage_class = "GLACIER"
    }

    expiration {
      days = 90
    }
  }
}

# Enable server access logging on the existing S3 bucket
resource "aws_s3_bucket_logging" "log_bucket_logging" {
  bucket        = "aws-cloudtrail-logs-132410971304-0971c04b"
  target_bucket = aws_s3_bucket.log_bucket.id
  target_prefix = "s3-access-logs/"
}


The provided Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Creates a new S3 bucket named `aws-cloudtrail-logs-132410971304-0971c04b-logs` to store the server access logs.
3. Enables versioning and configures a lifecycle rule to transition objects to Glacier after 30 days and delete them after 90 days.
4. Enables server access logging on the existing S3 bucket `aws-cloudtrail-logs-132410971304-0971c04b` and sends the logs to the newly created log bucket.