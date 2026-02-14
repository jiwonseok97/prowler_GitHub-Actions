resource "aws_s3_bucket" "remediation_aws_cloudtrail_logs" {
  bucket = var.s3_bucket_name

  versioning {
    enabled = true
    mfa_delete = true
  }

}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket for CloudTrail logs"
  type        = string
  default     = "aws-cloudtrail-logs-132410971304-0971c04b"
}