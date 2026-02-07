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
  bucket_name = "aws-cloudtrail-logs-132410971304-0971c04b"
  target_bucket = aws_s3_bucket.log_bucket.id
  target_prefix = "logs/"
}

# Enable CloudTrail data events on the existing S3 bucket
resource "aws_cloudtrail" "cloudtrail" {
  name                          = "cloudtrail-logs"
  s3_bucket_name                = "aws-cloudtrail-logs-132410971304-0971c04b"
  s3_key_prefix                 = "cloudtrail"
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true

  event_selector {
    read_write_type           = "All"
    include_management_events = true

    data_resource {
      type   = "AWS::S3::Object"
      values = ["arn:aws:s3:::aws-cloudtrail-logs-132410971304-0971c04b/"]
    }
  }
}


The provided Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Creates a new S3 bucket named `aws-cloudtrail-logs-132410971304-0971c04b-logs` for storing the server access logs.
3. Enables server access logging on the existing S3 bucket `aws-cloudtrail-logs-132410971304-0971c04b`, and sends the logs to the newly created log bucket.
4. Enables CloudTrail data events on the existing S3 bucket `aws-cloudtrail-logs-132410971304-0971c04b`, which provides object-level visibility for the bucket.