# Enable default SSE-KMS encryption on the S3 bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "remediation_s3_bucket_encryption" {
  bucket = "aws-cloudtrail-logs-132410971304-0971c04b"

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

# Attach a bucket policy to enforce KMS encryption
data "aws_kms_key" "remediation_kms_key" {
  key_id = "alias/aws/s3"
}

resource "aws_s3_bucket_policy" "remediation_s3_bucket_policy" {
  bucket = "aws-cloudtrail-logs-132410971304-0971c04b"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Deny",
        Principal = "*",
        Action = "s3:PutObject",
        Resource = "arn:aws:s3:::aws-cloudtrail-logs-132410971304-0971c04b/*",
        Condition = {
          "StringNotEquals" = {
            "s3:x-amz-server-side-encryption" = "aws:kms"
          },
          "Null" = {
            "s3:x-amz-server-side-encryption" = "false"
          }
        }
      }
    ]
  })
}

# Enable CloudTrail logging to the S3 bucket
resource "aws_cloudtrail" "remediation_cloudtrail" {
  name = "remediation-cloudtrail"
  s3_bucket_name                = "aws-cloudtrail-logs-132410971304-0971c04b"
  s3_key_prefix                 = "cloudtrail"
  is_multi_region_trail         = true
  include_global_service_events = true
}