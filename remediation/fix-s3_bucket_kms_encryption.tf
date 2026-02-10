# Create a new KMS key for S3 bucket encryption
resource "aws_kms_key" "remediation_s3_bucket_key" {
  description             = "KMS key for S3 bucket encryption"
  deletion_window_in_days = 30
  enable_key_rotation     = true
}

# Create a new S3 bucket server-side encryption configuration using the new KMS key
resource "aws_s3_bucket_server_side_encryption_configuration" "remediation_s3_bucket_encryption" {
  bucket = "aws-cloudtrail-logs-132410971304-0971c04b"

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.remediation_s3_bucket_key.key_id
      sse_algorithm     = "aws:kms"
    }
  }
}

# Create a new S3 bucket policy to enforce KMS encryption

resource "aws_s3_bucket_policy" "remediation_s3_bucket_policy" {
  bucket = "aws-cloudtrail-logs-132410971304-0971c04b"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Deny"
        Principal = "*"
        Action = "s3:PutObject"
        Resource = "arn:aws:s3:::aws-cloudtrail-logs-132410971304-0971c04b/*"
        Condition = {
          StringNotEquals = {
            "s3:x-amz-server-side-encryption" = "aws:kms"
            "s3:x-amz-server-side-encryption-aws-kms-key-id" = aws_kms_key.remediation_s3_bucket_key.key_id
          }
        }
      }
    ]
  })
}