# Enable MFA Delete on the S3 bucket (requires MFA)
resource "aws_s3_bucket_versioning" "remediation_s3_bucket_versioning" {
  count  = local.s3_do_mfa_delete ? 1 : 0
  bucket = local.s3_target_bucket_id
  mfa    = "${var.s3_mfa_serial} ${var.s3_mfa_token}"
  versioning_configuration {
    status = "Enabled"
    mfa_delete = "Enabled"
  }
}

# Restrict version purge actions on the S3 bucket
resource "aws_s3_bucket_ownership_controls" "remediation_s3_bucket_ownership_controls" {
  count  = local.s3_target_enabled ? 1 : 0
  bucket = local.s3_target_bucket_id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "remediation_s3_bucket_public_access_block" {
  count  = local.s3_target_enabled ? 1 : 0
  bucket = local.s3_target_bucket_id
  block_public_acls       = true
  block_public_policy    = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
