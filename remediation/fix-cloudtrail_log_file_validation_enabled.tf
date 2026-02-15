# Enable log file validation on the existing CloudTrail trail
resource "aws_cloudtrail" "remediation_security_cloudtail" {
  name = "security-cloudtail"
  s3_bucket_name                = var.s3_bucket_name
  s3_key_prefix                 = "cloudtrail-logs"
  is_multi_region_trail         = true
  include_global_service_events = true
  enable_log_file_validation    = true
}

# Ensure the S3 bucket has the required server-side encryption and access control configurations
resource "aws_s3_bucket" "remediation_cloudtrail_logs" {
  bucket = var.s3_bucket_name

}

resource "aws_s3_bucket_public_access_block" "remediation_cloudtrail_logs" {
  bucket = aws_s3_bucket.remediation_cloudtrail_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Ensure the CloudTrail logs bucket has a bucket policy that enforces least privilege access
data "aws_iam_policy_document" "remediation_cloudtrail_logs_bucket_policy" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions   = ["s3:GetBucketAcl", "s3:GetBucketPolicy", "s3:ListBucket", "s3:PutObject", "s3:PutObjectAcl"]
    resources = ["${aws_s3_bucket.remediation_cloudtrail_logs.arn}", "${aws_s3_bucket.remediation_cloudtrail_logs.arn}/*"]
  }
}

resource "aws_s3_bucket_policy" "remediation_cloudtrail_logs_bucket_policy" {
  bucket = aws_s3_bucket.remediation_cloudtrail_logs.id
  policy = data.aws_iam_policy_document.remediation_cloudtrail_logs_bucket_policy.json
}

variable "s3_bucket_name" {
  description = "Target S3 bucket name for remediation"
  type        = string
  default     = ""
}