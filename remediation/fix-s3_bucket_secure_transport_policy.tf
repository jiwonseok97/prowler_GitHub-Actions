# Modify the existing S3 bucket policy to enforce HTTPS-only access
resource "aws_s3_bucket_policy" "remediation_s3_bucket_policy" {
  bucket = var.s3_bucket_name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Deny"
        Principal = "*"
        Action = "s3:*"
        Resource = "arn:aws:s3:::${var.s3_bucket_name}/*"
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}


variable "s3_bucket_name" {
  type        = string
  description = "Name of the S3 bucket to apply the HTTPS-only policy to"
}