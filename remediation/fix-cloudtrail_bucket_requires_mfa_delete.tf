# Enable MFA Delete on the CloudTrail log bucket
resource "aws_s3_bucket_versioning" "remediation_cloudtrail_bucket_versioning" {
  bucket = "security-cloudtail"
  versioning_configuration {
    status = "Enabled"
    mfa_delete = "Enabled"
  }
}

# Enforce least privilege for CloudTrail log bucket access
data "aws_iam_policy_document" "remediation_cloudtrail_bucket_policy" {
  statement {
    effect = "Deny"
    actions = [
      "s3:DeleteObject",
      "s3:DeleteObjectVersion"
    ]
    resources = [
      "arn:aws:s3:::security-cloudtail/*"
    ]
    principals {
      type = "AWS"
      identifiers = ["*"]
    }
    condition {
      test     = "BoolIfExists"
      variable = "aws:MultiFactorAuthPresent"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "remediation_cloudtrail_bucket_policy" {
  bucket = "security-cloudtail"
  policy = data.aws_iam_policy_document.remediation_cloudtrail_bucket_policy.json
}

# Enable log file integrity validation
resource "aws_cloudtrail" "remediation_cloudtrail" {
  name                          = "security-cloudtail"
  s3_bucket_name                = "security-cloudtail"
  s3_key_prefix                 = "prefix"
  is_multi_region_trail         = true
  include_global_service_events = true
  enable_log_file_validation    = true
}