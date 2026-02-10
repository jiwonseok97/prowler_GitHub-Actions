# Create a new S3 bucket for CloudTrail logs access logging
resource "aws_s3_bucket" "remediation_cloudtrail_logs_access_logging" {
  bucket = "remediation-cloudtrail-logs-access-logging"

  versioning {
    enabled = true
  }

}

# Enable S3 server access logging on the existing CloudTrail logs bucket
resource "aws_s3_bucket_logging" "remediation_cloudtrail_logs_bucket_logging" {
  bucket        = "security-cloudtail"
  target_bucket = aws_s3_bucket.remediation_cloudtrail_logs_access_logging.id
  target_prefix = "cloudtrail-logs-access-logging/"
}

# Apply least privilege IAM policy to the CloudTrail logs bucket
data "aws_iam_policy_document" "remediation_cloudtrail_logs_bucket_policy" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetBucketAcl",
      "s3:GetBucketLocation",
      "s3:GetBucketLogging",
      "s3:GetBucketVersioning",
      "s3:PutBucketAcl",
      "s3:PutBucketLogging",
      "s3:PutBucketVersioning"
    ]
    resources = [
      "arn:aws:s3:::security-cloudtail",
      "arn:aws:s3:::security-cloudtail/*"
    ]
  }
}

resource "aws_s3_bucket_policy" "remediation_cloudtrail_logs_bucket_policy" {
  bucket = "security-cloudtail"
  policy = data.aws_iam_policy_document.remediation_cloudtrail_logs_bucket_policy.json
}