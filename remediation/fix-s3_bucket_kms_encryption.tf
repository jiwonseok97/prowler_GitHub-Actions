# Retrieve the existing S3 bucket
data "aws_s3_bucket" "remediation_bucket" {
  bucket = "aws-cloudtrail-logs-132410971304-0971c04b"
}

# Enable default SSE-KMS encryption on the S3 bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "remediation_bucket_encryption" {
  bucket = data.aws_s3_bucket.remediation_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

# Retrieve the existing KMS key used for encryption
data "aws_kms_key" "remediation_kms_key" {
  key_id = "alias/aws/s3"
}

# Enforce KMS encryption via bucket policy
data "aws_iam_policy_document" "remediation_bucket_policy" {
  statement {
    effect = "Deny"
    actions = [
      "s3:PutObject"
    ]
    resources = [
      "${data.aws_s3_bucket.remediation_bucket.arn}/*"
    ]
    condition {
      test     = "StringNotEquals"
      variable = "s3:x-amz-server-side-encryption"
      values   = ["aws:kms"]
    }
    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }
}

resource "aws_s3_bucket_policy" "remediation_bucket_policy" {
  bucket = data.aws_s3_bucket.remediation_bucket.id
  policy = data.aws_iam_policy_document.remediation_bucket_policy.json
}