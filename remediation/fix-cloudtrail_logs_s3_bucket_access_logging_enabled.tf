# Enable S3 server access logging on the CloudTrail logs bucket
data "aws_s3_bucket" "remediation_cloudtrail_logs_bucket" {
  bucket = "remediation-cloudtrail-logs-bucket"
}

# Create a separate, tightly controlled bucket for storing the S3 access logs
data "aws_s3_bucket" "remediation_cloudtrail_logs_bucket_access_logs" {
  bucket = "remediation-cloudtrail-logs-bucket-access-logs"
}

# Enable S3 server access logging on the CloudTrail logs bucket
resource "aws_s3_bucket_logging" "remediation_cloudtrail_logs_bucket_logging" {
  bucket = var.s3_bucket_name
  target_bucket = data.aws_s3_bucket.remediation_cloudtrail_logs_bucket_access_logs.id
  target_prefix = "cloudtrail-logs-bucket-access-logs/"
}

# Update the existing CloudTrail trail to use the new CloudTrail logs bucket
resource "aws_cloudtrail" "remediation_security_cloudtail" {
  name = "security-cloudtail"
  s3_bucket_name                = data.aws_s3_bucket.remediation_cloudtrail_logs_bucket.id
  s3_key_prefix                 = "cloudtrail-logs"
  is_multi_region_trail         = true
  include_global_service_events = true
  enable_log_file_validation    = true
}

variable "s3_bucket_name" {
  description = "Target S3 bucket name"
  type        = string
  default     = ""
}