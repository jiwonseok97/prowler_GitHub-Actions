# Modify the existing S3 bucket to disable ACLs and enforce bucket owner access control
data "aws_s3_bucket" "remediation_aws_cloudtrail_logs" {
  bucket = "aws-cloudtrail-logs-132410971304-0971c04b"
}

# Create a new S3 bucket policy to manage access using IAM and bucket policies
resource "aws_s3_bucket_policy" "remediation_aws_cloudtrail_logs_policy" {
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

# Enable server-side encryption for the S3 bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "remediation_aws_cloudtrail_logs_encryption" {
  bucket = data.aws_s3_bucket.remediation_aws_cloudtrail_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}