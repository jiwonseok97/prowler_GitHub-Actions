# Enable default SSE-KMS encryption on the existing S3 bucket
locals {
  s3_use_kms_key  = local.s3_target_enabled && (var.s3_create_kms_key || var.s3_kms_key_arn != "")
  s3_kms_key_arn  = var.s3_create_kms_key ? aws_kms_key.remediation_s3_bucket_key[0].arn : var.s3_kms_key_arn
  s3_do_cloudtrail = local.s3_target_enabled && var.s3_enable_cloudtrail && local.s3_use_kms_key
}

resource "aws_s3_bucket_server_side_encryption_configuration" "remediation_s3_bucket_encryption" {
  count  = local.s3_use_kms_key ? 1 : 0
  bucket = local.s3_target_bucket_id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
      kms_master_key_id = local.s3_kms_key_arn
    }
  }
}

# Create a customer-managed KMS key for the S3 bucket (optional)
resource "aws_kms_key" "remediation_s3_bucket_key" {
  count                   = local.s3_target_enabled && var.s3_create_kms_key ? 1 : 0
  description             = "Customer-managed key for S3 bucket encryption"
  deletion_window_in_days = 30
  enable_key_rotation     = true
}

# Attach a bucket policy to enforce KMS encryption
resource "aws_s3_bucket_policy" "remediation_s3_bucket_policy" {
  count  = local.s3_use_kms_key ? 1 : 0
  bucket = local.s3_target_bucket_id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Deny",
        Principal = "*",
        Action = "s3:PutObject",
        Resource = "${local.s3_target_bucket_arn}/*",
        Condition = {
          StringNotEquals = {
            "s3:x-amz-server-side-encryption" = "aws:kms"
            "s3:x-amz-server-side-encryption-aws-kms-key-id" = local.s3_kms_key_arn
          }
        }
      }
    ]
  })
}

# Monitor KMS key activity in CloudTrail
resource "aws_cloudtrail" "remediation_cloudtrail" {
  count                         = local.s3_do_cloudtrail ? 1 : 0
  name                          = "remediation-cloudtrail"
  s3_bucket_name                = local.s3_target_bucket_id
  s3_key_prefix                 = "cloudtrail"
  include_global_service_events = true
  is_multi_region_trail         = true
  kms_key_id                    = local.s3_kms_key_arn
}

# Consider using S3 Bucket Keys to control costs
resource "aws_s3_bucket_ownership_controls" "remediation_s3_bucket_ownership" {
  count  = local.s3_target_enabled ? 1 : 0
  bucket = local.s3_target_bucket_id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "remediation_s3_bucket_public_access" {
  count  = local.s3_target_enabled ? 1 : 0
  bucket = local.s3_target_bucket_id
  block_public_acls       = true
  block_public_policy    = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
