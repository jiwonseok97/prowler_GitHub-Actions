# S3 Bucket Hardening — applies CIS 1.4 controls to ALL discovered buckets
# Uses for_each so a single apply covers every non-compliant bucket.

variable "s3_bucket_names" {
  description = "List of S3 bucket names to harden"
  type        = list(string)
  default     = []
}

variable "kms_key_id" {
  description = "KMS key ID/ARN for S3 SSE-KMS (optional)"
  type        = string
  default     = ""
}

variable "s3_logging_bucket_name" {
  description = "S3 bucket name used as centralized server access logging target (optional)"
  type        = string
  default     = ""
}

locals {
  buckets          = toset(var.s3_bucket_names)
  kms_enabled      = var.kms_key_id != ""
  logging_enabled  = var.s3_logging_bucket_name != ""
  buckets_for_logs = local.logging_enabled ? { for b in local.buckets : b => b if b != var.s3_logging_bucket_name } : {}
}

# ── Default encryption (AES256) ─────────────────────────────────────────────
resource "aws_s3_bucket_server_side_encryption_configuration" "remediation_s3" {
  for_each = local.buckets
  bucket   = each.key

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = local.kms_enabled ? var.kms_key_id : null
    }
    bucket_key_enabled = true
  }
}

# ── Versioning ───────────────────────────────────────────────────────────────
resource "aws_s3_bucket_versioning" "remediation_s3" {
  for_each = local.buckets
  bucket   = each.key

  versioning_configuration {
    status = "Enabled"
  }
}

# ── Block public access ───────────────────────────────────────────────────────
resource "aws_s3_bucket_public_access_block" "remediation_s3" {
  for_each                = local.buckets
  bucket                  = each.key
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

# ── Secure transport (HTTPS-only bucket policy) ──────────────────────────────
resource "aws_s3_bucket_policy" "remediation_s3" {
  for_each = local.buckets
  bucket   = each.key

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "DenyNonSecureTransport"
      Effect    = "Deny"
      Principal = "*"
      Action    = "s3:*"
      Resource = [
        "arn:aws:s3:::${each.key}",
        "arn:aws:s3:::${each.key}/*"
      ]
      Condition = {
        Bool = { "aws:SecureTransport" = "false" }
      }
    }]
  })

  depends_on = [aws_s3_bucket_public_access_block.remediation_s3]
}

# ── Ownership controls (disable ACLs) ────────────────────────────────────────
resource "aws_s3_bucket_ownership_controls" "remediation_s3" {
  for_each = local.buckets
  bucket   = each.key

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_logging" "remediation_s3" {
  for_each      = local.buckets_for_logs
  bucket        = each.key
  target_bucket = var.s3_logging_bucket_name
  target_prefix = "s3-access/${each.key}/"
}
