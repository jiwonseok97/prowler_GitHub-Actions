# Enable server access logging on the existing S3 bucket
resource "aws_s3_bucket_logging" "remediation_bucket_logging" {
  count         = local.s3_target_enabled && local.s3_logging_enabled ? 1 : 0
  bucket        = local.s3_target_bucket_id
  target_bucket = local.s3_logging_bucket_id
  target_prefix = "s3-access-logs/"
}

# Enable CloudTrail data events on the existing S3 bucket
resource "aws_cloudtrail" "remediation_cloudtrail" {
  count                         = local.s3_target_enabled && var.s3_enable_cloudtrail ? 1 : 0
  name                          = "remediation-cloudtrail"
  s3_bucket_name                = local.s3_target_bucket_id
  s3_key_prefix                 = "cloudtrail-logs"
  is_multi_region_trail         = true
  include_global_service_events = true
  enable_log_file_validation    = true

  event_selector {
    read_write_type           = "All"
    include_management_events = true

    data_resource {
      type   = "AWS::S3::Object"
      values = ["${local.s3_target_bucket_arn}/"]
    }
  }
}

# Apply defense in depth by centralizing logs and protecting them from tampering
resource "aws_kms_key" "remediation_log_protection_key" {
  count                   = local.s3_logging_enabled && var.s3_create_logging_kms_key ? 1 : 0
  description             = "KMS key for protecting log files"
  deletion_window_in_days = 30
}

resource "aws_kms_alias" "remediation_log_protection_key_alias" {
  count         = local.s3_logging_enabled && var.s3_create_logging_kms_key ? 1 : 0
  name          = "alias/remediation-log-protection-key"
  target_key_id = aws_kms_key.remediation_log_protection_key[0].id
}

resource "aws_s3_bucket_server_side_encryption_configuration" "remediation_logging_bucket_encryption" {
  count  = local.s3_logging_enabled && (var.s3_create_logging_kms_key || var.s3_logging_kms_key_arn != "") ? 1 : 0
  bucket = local.s3_logging_bucket_id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.s3_create_logging_kms_key ? aws_kms_key.remediation_log_protection_key[0].id : var.s3_logging_kms_key_arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_ownership_controls" "remediation_logging_bucket_ownership" {
  count  = local.s3_logging_enabled ? 1 : 0
  bucket = local.s3_logging_bucket_id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "remediation_logging_bucket_acl" {
  count  = local.s3_logging_enabled && var.s3_enable_bucket_acl ? 1 : 0
  bucket = local.s3_logging_bucket_id
  acl    = "private"
}

resource "aws_s3_bucket_public_access_block" "remediation_logging_bucket_public_access_block" {
  count                   = local.s3_logging_enabled ? 1 : 0
  bucket                  = local.s3_logging_bucket_id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
