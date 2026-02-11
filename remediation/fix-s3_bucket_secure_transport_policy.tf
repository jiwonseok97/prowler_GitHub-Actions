# Modify the existing S3 bucket policy to enforce HTTPS-only access
resource "aws_s3_bucket_policy" "remediation_s3_bucket_policy" {
  count  = local.s3_target_enabled ? 1 : 0
  bucket = local.s3_target_bucket_id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Deny"
        Principal = "*"
        Action = "s3:*"
        Resource = "${local.s3_target_bucket_arn}/*"
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}
