# Create a new S3 bucket with default SSE-KMS encryption
resource "aws_s3_bucket" "remediation_aws_cloudtrail_logs" {
  bucket = "aws-cloudtrail-logs-132410971304-0971c04b"
  acl    = "private"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "aws:kms"
      }
    }
  }
}

# Create a new customer-managed KMS key for S3 bucket encryption
resource "aws_kms_key" "remediation_s3_bucket_key" {
  description             = "Customer-managed key for S3 bucket encryption"
  deletion_window_in_days = 30
  policy                  = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::132410971304:root"
        },
        Action = [
          "kms:*"
        ],
        Resource = "*"
      }
    ]
  })
}

# Attach the customer-managed KMS key to the S3 bucket
resource "aws_s3_bucket_ownership_controls" "remediation_s3_bucket_ownership" {
  bucket = aws_s3_bucket.remediation_aws_cloudtrail_logs.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "remediation_s3_bucket_encryption" {
  bucket = aws_s3_bucket.remediation_aws_cloudtrail_logs.id
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.remediation_s3_bucket_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

# Add a bucket policy to enforce KMS encryption
resource "aws_s3_bucket_policy" "remediation_s3_bucket_policy" {
  bucket = aws_s3_bucket.remediation_aws_cloudtrail_logs.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Deny",
        Principal = "*",
        Action = "s3:PutObject",
        Resource = "${aws_s3_bucket.remediation_aws_cloudtrail_logs.arn}/*",
        Condition = {
          StringNotEquals = {
            "s3:x-amz-server-side-encryption" = "aws:kms"
          }
        }
      }
    ]
  })
}