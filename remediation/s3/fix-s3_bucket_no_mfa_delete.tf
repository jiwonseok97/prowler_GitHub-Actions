resource "aws_s3_bucket" "remediation_aws_cloudtrail_logs" {
  bucket = var.s3_bucket_name

  versioning {
    enabled    = true
    mfa_delete = true
  }

}

resource "aws_s3_bucket_public_access_block" "remediation_aws_cloudtrail_logs" {
  bucket = aws_s3_bucket.remediation_aws_cloudtrail_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket for CloudTrail logs"
  type        = string
  default     = "aws-cloudtrail-logs-132410971304-0971c04b"
}
