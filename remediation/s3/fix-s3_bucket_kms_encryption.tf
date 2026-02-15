variable "s3_bucket_name" {
  type        = string
  description = "Name of the S3 bucket for CloudTrail logs"
}

variable "kms_key_id" {
  type        = string
  description = "ID of the KMS key used for S3 bucket encryption"
}

data "aws_kms_key" "remediation_s3_bucket_kms_key" {
  key_id = var.kms_key_id
}

resource "aws_s3_bucket_server_side_encryption_configuration" "remediation_s3_bucket_encryption" {
  bucket = var.s3_bucket_name

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.kms_key_id
    }
  }
}

resource "aws_s3_bucket_policy" "remediation_s3_bucket_policy" {
  bucket = var.s3_bucket_name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Deny",
        Principal = "*",
        Action    = "s3:PutObject",
        Resource  = "arn:aws:s3:::${var.s3_bucket_name}/*",
        Condition = {
          StringNotEquals = {
            "s3:x-amz-server-side-encryption"                = "aws:kms"
            "s3:x-amz-server-side-encryption-aws-kms-key-id" = data.aws_kms_key.remediation_s3_bucket_kms_key.key_id
          }
        }
      }
    ]
  })
}
