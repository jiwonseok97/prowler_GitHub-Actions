# S3 Bucket Hardening — applies CIS 1.4 controls to ALL discovered buckets
# Uses for_each so a single apply covers every non-compliant bucket.

variable "s3_bucket_names" {
  description = "List of S3 bucket names to harden"
  type        = list(string)
  default     = []
}

locals {
  buckets = toset(var.s3_bucket_names)
}

# ── Default encryption (AES256) ─────────────────────────────────────────────
resource "aws_s3_bucket_server_side_encryption_configuration" "remediation_s3" {
  for_each = local.buckets
  bucket   = each.key

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
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
