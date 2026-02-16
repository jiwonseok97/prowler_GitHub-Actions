# Update the S3 bucket to disable ACLs and manage access with IAM and bucket policies
data "aws_s3_bucket" "remediation_aws_cloudtrail_logs" {
  bucket = "aws-cloudtrail-logs-132410971304-0971c04b"
}

# Ensure the bucket has server-side encryption enabled
resource "aws_s3_bucket_server_side_encryption_configuration" "remediation_aws_cloudtrail_logs" {
  bucket = data.aws_s3_bucket.remediation_aws_cloudtrail_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Attach a bucket policy to manage access
resource "aws_s3_bucket_policy" "remediation_aws_cloudtrail_logs" {
  bucket = data.aws_s3_bucket.remediation_aws_cloudtrail_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          AWS = "*"
        },
        Action = [
          "s3:GetBucketAcl",
          "s3:GetBucketPolicy",
          "s3:ListBucket",
          "s3:PutBucketAcl",
          "s3:PutBucketPolicy"
        ],
        Resource = [
          "arn:aws:s3:::aws-cloudtrail-logs-132410971304-0971c04b",
          "arn:aws:s3:::aws-cloudtrail-logs-132410971304-0971c04b/*"
        ]
      }
    ]
  })
}

variable "s3_bucket_name" {
  description = "Target S3 bucket name for remediation"
  type        = string
  default     = "aws-cloudtrail-logs-132410971304-0971c04b"
}
