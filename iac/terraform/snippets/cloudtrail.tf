# CloudTrail Hardening — imports and hardens the existing trail
# Enables: log file validation, multi-region, CloudWatch Logs integration
# Also hardens the trail's S3 bucket (versioning, encryption, public access)

variable "cloudtrail_name" {
  description = "Existing CloudTrail trail name to harden"
  type        = string
  default     = ""
}

variable "s3_bucket_name" {
  description = "Existing CloudTrail log bucket name"
  type        = string
  default     = ""
}

variable "cloudwatch_log_group_name" {
  description = "Existing CW Logs group name for CloudTrail (leave empty to auto-create)"
  type        = string
  default     = ""
}

locals {
  trail_enabled   = var.cloudtrail_name != ""
  bucket_enabled  = var.s3_bucket_name != ""
  use_existing_lg = var.cloudwatch_log_group_name != ""
  # Fixed name shared with cloudwatch_cis_filters.tf
  ct_log_group_name = local.use_existing_lg ? var.cloudwatch_log_group_name : "/cloudtrail/remediation"
}

# ── CloudWatch Log Group for CloudTrail events ─────────────────────────────
resource "aws_cloudwatch_log_group" "remediation_ct" {
  count             = local.use_existing_lg ? 0 : 1
  name              = "/cloudtrail/remediation"
  retention_in_days = 365
}

# ── IAM Role: allows CloudTrail to write to CloudWatch Logs ────────────────
resource "aws_iam_role" "remediation_ct_cw" {
  count = local.trail_enabled ? 1 : 0
  name  = "remediation-cloudtrail-cw-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "cloudtrail.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  lifecycle { ignore_changes = [tags] }
}

resource "aws_iam_role_policy" "remediation_ct_cw" {
  count = local.trail_enabled ? 1 : 0
  name  = "remediation-cloudtrail-cw-policy"
  role  = aws_iam_role.remediation_ct_cw[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["logs:CreateLogStream", "logs:PutLogEvents"]
      Resource = "arn:aws:logs:*:*:log-group:${local.ct_log_group_name}:*"
    }]
  })
}

# ── Harden existing CloudTrail trail ───────────────────────────────────────
# auto_import.sh imports this using the existing trail ARN
resource "aws_cloudtrail" "remediation_existing" {
  count = local.trail_enabled ? 1 : 0

  name           = var.cloudtrail_name
  s3_bucket_name = var.s3_bucket_name

  enable_log_file_validation    = true
  is_multi_region_trail         = true
  include_global_service_events = true
  enable_logging                = true

  cloud_watch_logs_group_arn = local.use_existing_lg ? (
    "${var.cloudwatch_log_group_name}:*"
  ) : "${aws_cloudwatch_log_group.remediation_ct[0].arn}:*"
  cloud_watch_logs_role_arn = aws_iam_role.remediation_ct_cw[0].arn

  lifecycle {
    ignore_changes = [tags, kms_key_id, event_selector, advanced_event_selector]
  }
}

# ── S3 bucket hardening ────────────────────────────────────────────────────
resource "aws_s3_bucket_versioning" "remediation_cloudtrail_logs_versioning" {
  count  = local.bucket_enabled ? 1 : 0
  bucket = var.s3_bucket_name
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "remediation_cloudtrail_logs_encryption" {
  count  = local.bucket_enabled ? 1 : 0
  bucket = var.s3_bucket_name
  rule {
    apply_server_side_encryption_by_default { sse_algorithm = "AES256" }
  }
}

resource "aws_s3_bucket_public_access_block" "remediation_cloudtrail_logs_public_access_block" {
  count                   = local.bucket_enabled ? 1 : 0
  bucket                  = var.s3_bucket_name
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}
