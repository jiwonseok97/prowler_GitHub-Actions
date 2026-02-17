# Enable MFA Delete on the S3 bucket
resource "aws_s3_bucket_versioning" "remediation_s3_bucket_versioning" {
  bucket = var.s3_bucket_name
  versioning_configuration {
    status     = "Enabled"
    mfa_delete = "Disabled"
  }
}

# Restrict version purge actions on the S3 bucket
data "aws_iam_policy_document" "remediation_s3_bucket_policy" {
  statement {
    effect = "Deny"
    actions = [
      "s3:DeleteObjectVersion",
      "s3:PermanentDelete"
    ]
    resources = [
      "arn:aws:s3:::${var.s3_bucket_name}/*"
    ]
    principals {
      type        = "*"
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
  bucket = var.s3_bucket_name
  policy = data.aws_iam_policy_document.remediation_s3_bucket_policy.json
}

variable "s3_bucket_name" {
  description = "Target S3 bucket name"
  type        = string
  default     = ""
}
