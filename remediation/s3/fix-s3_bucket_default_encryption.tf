# Enable default encryption on the existing S3 bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "remediation_s3_bucket_encryption" {
  bucket = "aws-cloudtrail-logs-132410971304-0971c04b"

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Attach the S3 bucket encryption configuration to the existing bucket
resource "aws_s3_bucket_ownership_controls" "remediation_s3_bucket_ownership" {
  bucket = "aws-cloudtrail-logs-132410971304-0971c04b"

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}
