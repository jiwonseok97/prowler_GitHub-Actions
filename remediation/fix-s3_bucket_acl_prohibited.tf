# Disable ACLs and manage access with IAM and bucket policies
resource "aws_s3_bucket" "remediation_aws_cloudtrail_logs" {
  bucket = var.s3_bucket_name

}

# Ensure server-side encryption is enabled
resource "aws_s3_bucket_server_side_encryption_configuration" "remediation_aws_cloudtrail_logs" {
  bucket = aws_s3_bucket.remediation_aws_cloudtrail_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket for CloudTrail logs"
  type        = string
  default     = "aws-cloudtrail-logs-132410971304-0971c04b"
}