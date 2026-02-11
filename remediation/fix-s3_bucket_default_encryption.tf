# Enable default server-side encryption (SSE) on the existing S3 bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "remediation_s3_bucket_encryption" {
  count  = local.s3_target_enabled ? 1 : 0
  bucket = local.s3_target_bucket_id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Ensure the bucket has the correct ACL (private) if ACLs are allowed
resource "aws_s3_bucket_acl" "remediation_s3_bucket_acl" {
  count  = local.s3_target_enabled && var.s3_enable_bucket_acl ? 1 : 0
  bucket = local.s3_target_bucket_id
  acl    = "private"
}
