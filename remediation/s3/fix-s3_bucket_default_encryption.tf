# Enable default encryption on the existing S3 bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "remediation_s3_bucket_encryption" {
  bucket = "aws-cloudtrail-logs-132410971304-0971c04b"

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.remediation_s3_bucket_key.arn
    }
  }
}

# Create a new KMS key for encrypting the S3 bucket
resource "aws_kms_key" "remediation_s3_bucket_key" {
  description             = "KMS key for encrypting S3 bucket aws-cloudtrail-logs-132410971304-0971c04b"
  deletion_window_in_days = 30
  enable_key_rotation     = true
}

# Attach the KMS key policy to the new KMS key
resource "aws_kms_key_policy" "remediation_s3_bucket_key_policy" {

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        Action   = "kms:*",
        Resource = "*"
      }
    ]
  })
  key_id = aws_kms_key.remediation_s3_bucket_key.key_id
}
