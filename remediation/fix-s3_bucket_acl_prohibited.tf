# Modify the existing S3 bucket to disable ACLs and manage access with IAM and bucket policies
resource "aws_s3_bucket" "remediation_aws_cloudtrail_logs" {
  bucket = "aws-cloudtrail-logs-132410971304-0971c04b"

  # Set Object Ownership to BucketOwnerEnforced
}

# Create an IAM policy to grant the necessary permissions to the bucket
data "aws_iam_policy_document" "remediation_aws_cloudtrail_logs_policy" {
  statement {
    effect = "Allow"
    actions = [
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

resource "aws_iam_policy" "remediation_aws_cloudtrail_logs_policy" {
  name        = "remediation-aws-cloudtrail-logs-policy"
  description = "Policy to manage access to the aws-cloudtrail-logs-132410971304-0971c04b S3 bucket"
  policy      = data.aws_iam_policy_document.remediation_aws_cloudtrail_logs_policy.json
}

# Attach the IAM policy to the appropriate IAM user or role