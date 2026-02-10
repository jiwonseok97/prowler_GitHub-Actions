# Enable default SSE-KMS encryption on the S3 bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "remediation_s3_bucket_encryption" {
  bucket = "aws-cloudtrail-logs-132410971304-0971c04b"

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
      kms_master_key_id = aws_kms_key.remediation_s3_bucket_key.arn
    }
  }
}

# Create a customer-managed KMS key for the S3 bucket
resource "aws_kms_key" "remediation_s3_bucket_key" {
  description             = "Customer-managed key for S3 bucket encryption"
  deletion_window_in_days = 30
  enable_key_rotation     = true
}

# Attach a bucket policy to enforce KMS encryption
data "aws_s3_bucket" "remediation_s3_bucket" {
  bucket = "aws-cloudtrail-logs-132410971304-0971c04b"
}

resource "aws_s3_bucket_policy" "remediation_s3_bucket_policy" {
  bucket = data.aws_s3_bucket.remediation_s3_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Deny",
        Principal = "*",
        Action = "s3:PutObject",
        Resource = "${data.aws_s3_bucket.remediation_s3_bucket.arn}/*",
        Condition = {
          StringNotEquals = {
            "s3:x-amz-server-side-encryption" = "aws:kms"
          }
        }
      }
    ]
  })
}

# Monitor KMS key activity in CloudTrail
resource "aws_cloudtrail" "remediation_cloudtrail" {
  name                          = "remediation-cloudtrail"
  s3_bucket_name                = data.aws_s3_bucket.remediation_s3_bucket.id
  s3_key_prefix                 = "cloudtrail"
  include_global_service_events = true
  is_multi_region_trail         = true
  kms_key_id                    = aws_kms_key.remediation_s3_bucket_key.arn
}