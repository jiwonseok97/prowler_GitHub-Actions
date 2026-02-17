#
# Enable default SSE-KMS encryption for the S3 bucket
#
resource "aws_s3_bucket_server_side_encryption_configuration" "remediation_s3_bucket_encryption" {
  bucket = "aws-cloudtrail-logs-132410971304-0971c04b"

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

#
# Attach a customer-managed KMS key to the S3 bucket
#
resource "aws_kms_key" "remediation_s3_bucket_kms_key" {
  description             = "Customer-managed key for S3 bucket encryption"
  deletion_window_in_days = 30
}

resource "aws_s3_bucket_ownership_controls" "remediation_s3_bucket_ownership" {
  bucket = "aws-cloudtrail-logs-132410971304-0971c04b"

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}


resource "aws_s3_bucket_public_access_block" "remediation_s3_bucket_public_access" {
  bucket = "aws-cloudtrail-logs-132410971304-0971c04b"

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

#
# Enforce KMS encryption via bucket policy
#
data "aws_iam_policy_document" "remediation_s3_bucket_policy" {
  statement {
    effect = "Deny"
    actions = [
      "s3:PutObject"
    ]
    resources = [
      "arn:aws:s3:::aws-cloudtrail-logs-132410971304-0971c04b/*"
    ]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    condition {
      test     = "StringNotEquals"
      variable = "s3:x-amz-server-side-encryption"
      values   = ["aws:kms"]
    }
  }
}

resource "aws_s3_bucket_policy" "remediation_s3_bucket_policy" {
  bucket = "aws-cloudtrail-logs-132410971304-0971c04b"
  policy = data.aws_iam_policy_document.remediation_s3_bucket_policy.json
}
