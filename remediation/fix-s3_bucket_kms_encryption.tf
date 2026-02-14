# Enable default SSE-KMS encryption for the S3 bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "remediation_s3_bucket_encryption" {
  bucket = var.s3_bucket_name

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

# Enforce KMS encryption via bucket policy
data "aws_kms_key" "remediation_s3_bucket_kms_key" {
  key_id = "alias/aws/s3"
}

resource "aws_s3_bucket_policy" "remediation_s3_bucket_policy" {
  bucket = var.s3_bucket_name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Deny",
        Principal = "*",
        Action = "s3:PutObject",
        Resource = "arn:aws:s3:::${var.s3_bucket_name}/*",
        Condition = {
          StringNotEquals = {
            "s3:x-amz-server-side-encryption" = "aws:kms"
          }
        }
      }
    ]
  })
}


variable "s3_bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
}