# Enable MFA Delete on the S3 bucket
resource "aws_s3_bucket_versioning" "remediation_s3_bucket_versioning" {
  bucket = "aws-cloudtrail-logs-132410971304-0971c04b"
  versioning_configuration {
    status = "Enabled"
    mfa_delete = "Disabled"
  }
}

# Add a bucket policy to restrict version purge actions
data "aws_iam_policy_document" "remediation_s3_bucket_policy" {
  statement {
    effect = "Deny"
    actions = [
      "s3:DeleteObjectVersion",
      "s3:PutBucketVersioning",
      "s3:PutBucketVersioning"
    ]
    resources = [
      "arn:aws:s3:::aws-cloudtrail-logs-132410971304-0971c04b",
      "arn:aws:s3:::aws-cloudtrail-logs-132410971304-0971c04b/*"
    ]
    principals {
      type = "*"
      identifiers = ["*"]
    }
    condition {
      test     = "Bool"
      variable = "aws:MultiFactorAuthPresent"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "remediation_s3_bucket_policy" {
  bucket = "aws-cloudtrail-logs-132410971304-0971c04b"
  policy = data.aws_iam_policy_document.remediation_s3_bucket_policy.json
}