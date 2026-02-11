# Disable ACLs by enforcing BucketOwnerEnforced ownership on the existing bucket.
resource "aws_s3_bucket_ownership_controls" "remediation_acl_prohibited" {
  count  = local.s3_target_enabled ? 1 : 0
  bucket = local.s3_target_bucket_id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}
