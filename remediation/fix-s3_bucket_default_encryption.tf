# Enable default server-side encryption (SSE) on the S3 bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "remediation_s3_bucket_encryption" {
  bucket = "aws-cloudtrail-logs-132410971304-0971c04b"

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Ensure the bucket has the correct ACL (private)
resource "aws_s3_bucket_acl" "remediation_s3_bucket_acl" {
  bucket = "aws-cloudtrail-logs-132410971304-0971c04b"
  acl    = "private"
}