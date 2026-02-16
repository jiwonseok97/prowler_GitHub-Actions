# Update the S3 bucket to disable ACLs and manage access with IAM and bucket policies
data "aws_s3_bucket" "remediation_aws_cloudtrail_logs" {
  bucket = "aws-cloudtrail-logs-132410971304-0971c04b"
}

# Create a new S3 bucket server-side encryption configuration
resource "aws_s3_bucket_server_side_encryption_configuration" "remediation_aws_cloudtrail_logs_encryption" {
  bucket = data.aws_s3_bucket.remediation_aws_cloudtrail_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

variable "s3_bucket_name" {
  description = "Target S3 bucket name for remediation"
  type        = string
  default     = "aws-cloudtrail-logs-132410971304-0971c04b"
}
