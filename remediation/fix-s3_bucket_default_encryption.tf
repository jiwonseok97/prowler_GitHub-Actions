# Enable default encryption on the existing S3 bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "remediation_s3_bucket_encryption" {
  bucket = "aws-cloudtrail-logs-132410971304-0971c04b"

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

# Attach a bucket policy to enforce encryption
data "aws_iam_policy_document" "remediation_s3_bucket_encryption_policy" {
  statement {
    sid       = "DenyUnencryptedObjectUploads"
    effect    = "Deny"
    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::aws-cloudtrail-logs-132410971304-0971c04b/*"]

    condition {
      test     = "StringNotEquals"
      variable = "s3:x-amz-server-side-encryption"
      values   = ["aws:kms"]
    }
  }
}

resource "aws_s3_bucket_policy" "remediation_s3_bucket_encryption_policy" {
  bucket = "aws-cloudtrail-logs-132410971304-0971c04b"
  policy = data.aws_iam_policy_document.remediation_s3_bucket_encryption_policy.json
}