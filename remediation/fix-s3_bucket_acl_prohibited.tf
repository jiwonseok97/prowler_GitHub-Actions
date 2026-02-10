# Modify the existing S3 bucket to disable ACLs and manage access with IAM and bucket policies
resource "aws_s3_bucket" "remediation_aws_cloudtrail_logs" {
  bucket = "aws-cloudtrail-logs-132410971304-0971c04b"

  # Enable bucket ownership control
}

# Create a new IAM policy to grant the necessary permissions for the S3 bucket
resource "aws_iam_policy" "remediation_s3_bucket_policy" {
  name        = "remediation-s3-bucket-policy"
  description = "Policy to manage access to the S3 bucket"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:PutObject"
        ],
        Resource = [
          "arn:aws:s3:::aws-cloudtrail-logs-132410971304-0971c04b",
          "arn:aws:s3:::aws-cloudtrail-logs-132410971304-0971c04b/*"
        ]
      }
    ]
  })
}

# Attach the IAM policy to the appropriate IAM user(s) or role(s)
resource "aws_iam_user_policy_attachment" "remediation_s3_bucket_policy_attachment" {
  user       = "your-iam-user-name"
  policy_arn = aws_iam_policy.remediation_s3_bucket_policy.arn
}

# Enable server-side encryption for the S3 bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "remediation_s3_bucket_encryption" {
  bucket = aws_s3_bucket.remediation_aws_cloudtrail_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}