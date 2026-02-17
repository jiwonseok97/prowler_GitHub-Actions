#Enforce HTTPS-only access to the S3 bucket
resource "aws_s3_bucket_policy" "remediation_s3_bucket_secure_transport_policy" {
  bucket = var.s3_bucket_name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource  = "arn:aws:s3:::${var.s3_bucket_name}/*"
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
  description = "Target S3 bucket name"
  type        = string
  default     = ""
}
