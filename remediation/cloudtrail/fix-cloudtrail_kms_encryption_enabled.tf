resource "aws_cloudtrail" "remediation_security_cloudtail" {
  name                          = "security-cloudtail"
  s3_bucket_name                = var.s3_bucket_name
  s3_key_prefix                 = "cloudtrail-logs"
  is_multi_region_trail         = true
  include_global_service_events = true
  kms_key_id                    = aws_kms_key.remediation_cloudtrail_kms_key.arn
}

resource "aws_kms_key" "remediation_cloudtrail_kms_key" {
  description             = "KMS key for CloudTrail encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true
}

resource "aws_kms_alias" "remediation_cloudtrail_kms_key_alias" {
  name          = "alias/alias-remediation-cloudtrail-kms-key"
  target_key_id = aws_kms_key.remediation_cloudtrail_kms_key.id
}

resource "aws_s3_bucket" "remediation_cloudtrail_logs_bucket" {
  bucket = var.s3_bucket_name

}

resource "aws_s3_bucket_public_access_block" "remediation_cloudtrail_logs_bucket_access" {
  bucket = aws_s3_bucket.remediation_cloudtrail_logs_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket for CloudTrail logs"
  type        = string
}

resource "aws_s3_bucket_policy" "remediation_cloudtrail_bucket_policy" {
  bucket = var.s3_bucket_name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AWSCloudTrailAclCheck"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:GetBucketAcl"
        Resource  = "arn:aws:s3:::${var.s3_bucket_name}"
      },
      {
        Sid       = "AWSCloudTrailWrite"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = "arn:aws:s3:::${var.s3_bucket_name}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}
