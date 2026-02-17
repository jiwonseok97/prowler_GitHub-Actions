# Enable S3 versioning for the existing bucket
resource "aws_s3_bucket_versioning" "remediation_s3_bucket_versioning" {
  bucket = "aws-cloudtrail-logs-132410971304-0971c04b"
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable S3 bucket encryption using server-side encryption with Amazon S3-managed keys (SSE-S3)
resource "aws_s3_bucket_server_side_encryption_configuration" "remediation_s3_bucket_encryption" {
  bucket = "aws-cloudtrail-logs-132410971304-0971c04b"
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Apply a bucket policy to enforce MFA delete for the S3 bucket
data "aws_iam_policy_document" "remediation_s3_bucket_policy" {
  statement {
    effect = "Deny"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions = [
      "s3:DeleteObject",
      "s3:DeleteObjectVersion"
    ]
    resources = [
      "arn:aws:s3:::aws-cloudtrail-logs-132410971304-0971c04b/*"
    ]
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

# Apply a lifecycle rule to manage noncurrent object versions
resource "aws_s3_bucket_lifecycle_configuration" "remediation_s3_bucket_lifecycle" {
  bucket = "aws-cloudtrail-logs-132410971304-0971c04b"
  rule {
    id     = "lifecycle-rule-1"
    status = "Enabled"
    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}
