# CloudTrail Hardening — imports and hardens the existing trail
# Enables: log file validation, multi-region, CloudWatch Logs integration
# Also hardens the trail's S3 bucket (versioning, encryption, public access)

variable "cloudtrail_trails" {
  description = "Map of CloudTrail trail name => S3 log bucket name"
  type        = map(string)
  default     = {}
}

# Backward compatibility for old generated tfvars.
variable "cloudtrail_name" {
  description = "Legacy: single CloudTrail trail name"
  type        = string
  default     = ""
}

# Backward compatibility for old generated tfvars.
variable "s3_bucket_name" {
  description = "Legacy: single CloudTrail log bucket name"
  type        = string
  default     = ""
}

variable "cloudwatch_log_group_name" {
  description = "Existing CW Logs group name for CloudTrail (leave empty to auto-create)"
  type        = string
  default     = ""
}

variable "kms_key_id" {
  description = "KMS key ID/ARN for CloudTrail log encryption (optional)"
  type        = string
  default     = ""
}

variable "log_bucket_name" {
  description = "Target S3 bucket for CloudTrail log bucket access logging (optional)"
  type        = string
  default     = ""
}

locals {
  legacy_trails   = var.cloudtrail_name != "" ? { (var.cloudtrail_name) = var.s3_bucket_name } : {}
  trail_map       = length(var.cloudtrail_trails) > 0 ? var.cloudtrail_trails : local.legacy_trails
  trail_enabled   = length(local.trail_map) > 0
  bucket_names    = toset([for b in values(local.trail_map) : b if b != ""])
  bucket_enabled  = length(local.bucket_names) > 0
  use_existing_lg = var.cloudwatch_log_group_name != ""
  kms_enabled     = var.kms_key_id != ""
  logging_enabled = var.log_bucket_name != ""
  # Fixed name shared with cloudwatch_cis_filters.tf
  ct_log_group_name = local.use_existing_lg ? var.cloudwatch_log_group_name : "/cloudtrail/remediation"
}

# ── CloudWatch Log Group for CloudTrail events ─────────────────────────────
resource "aws_cloudwatch_log_group" "remediation_ct" {
  count             = local.use_existing_lg ? 0 : 1
  name              = "cloudtrail-remediation"
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
  for_each = local.trail_map

  name           = each.key
  s3_bucket_name = each.value

  enable_log_file_validation    = true
  is_multi_region_trail         = true
  include_global_service_events = true
  enable_logging                = true
  kms_key_id                    = local.kms_enabled ? var.kms_key_id : null

  cloud_watch_logs_group_arn = local.use_existing_lg ? (
    "${var.cloudwatch_log_group_name}:*"
  ) : "${aws_cloudwatch_log_group.remediation_ct[0].arn}:*"
  cloud_watch_logs_role_arn = aws_iam_role.remediation_ct_cw[0].arn

  lifecycle {
    ignore_changes = [tags, event_selector, advanced_event_selector]
  }
}

# ── S3 bucket hardening ────────────────────────────────────────────────────
resource "aws_s3_bucket_versioning" "remediation_cloudtrail_logs_versioning" {
  for_each = local.bucket_names
  bucket   = each.value
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "remediation_cloudtrail_logs_encryption" {
  for_each = local.bucket_names
  bucket   = each.value
  rule {
    apply_server_side_encryption_by_default { sse_algorithm = "AES256" }
  }
}

resource "aws_s3_bucket_public_access_block" "remediation_cloudtrail_logs_public_access_block" {
  for_each                = local.bucket_names
  bucket                  = each.value
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_logging" "remediation_cloudtrail_logs_access_logging" {
  for_each      = local.logging_enabled ? { for b in local.bucket_names : b => b if b != var.log_bucket_name } : {}
  bucket        = each.value
  target_bucket = var.log_bucket_name
  target_prefix = "cloudtrail-access/"
}
