# Update the S3 bucket to disable ACLs and manage access with IAM and bucket policies
data "aws_s3_bucket" "remediation_aws_cloudtrail_logs" {
  bucket = "aws-cloudtrail-logs-132410971304-0971c04b"
}

# Create an S3 bucket policy to manage access
data "aws_iam_policy_document" "remediation_aws_cloudtrail_logs_policy" {
  statement {
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions = [
      "s3:GetBucketAcl",
      "s3:GetBucketPolicy",
      "s3:ListBucket",
      "s3:PutBucketAcl",
      "s3:PutBucketPolicy",
    ]
    resources = [
      data.aws_s3_bucket.remediation_aws_cloudtrail_logs.arn,
      "${data.aws_s3_bucket.remediation_aws_cloudtrail_logs.arn}/*",
    ]
  }
}

resource "aws_s3_bucket_policy" "remediation_aws_cloudtrail_logs_policy" {
  bucket = data.aws_s3_bucket.remediation_aws_cloudtrail_logs.id
  policy = data.aws_iam_policy_document.remediation_aws_cloudtrail_logs_policy.json
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

variable "s3_bucket_name" {
  description = "Target S3 bucket name for remediation"
  type        = string
  default     = "aws-cloudtrail-logs-132410971304-0971c04b"
}
