# Modify the existing S3 bucket to disable ACLs and manage access with IAM and bucket policies
resource "aws_s3_bucket" "remediation_aws_cloudtrail_logs" {
  bucket = "aws-cloudtrail-logs-132410971304-0971c04b"

  # Enable bucket ownership control
}

# Create a new IAM policy to grant the necessary permissions for the CloudTrail logs bucket
data "aws_iam_policy_document" "remediation_cloudtrail_logs_bucket_policy" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetBucketAcl",
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:PutObject"
    ]
    resources = [
      "arn:aws:s3:::aws-cloudtrail-logs-132410971304-0971c04b",
      "arn:aws:s3:::aws-cloudtrail-logs-132410971304-0971c04b/*"
    ]
  }
}

resource "aws_s3_bucket_policy" "remediation_cloudtrail_logs_bucket_policy" {
  bucket = aws_s3_bucket.remediation_aws_cloudtrail_logs.id
  policy = data.aws_iam_policy_document.remediation_cloudtrail_logs_bucket_policy.json
}

# Enable server-side encryption for the CloudTrail logs bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "remediation_cloudtrail_logs_encryption" {
  bucket = aws_s3_bucket.remediation_aws_cloudtrail_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}