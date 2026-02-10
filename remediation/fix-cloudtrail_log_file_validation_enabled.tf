# Enable log file validation on the existing CloudTrail trail
resource "aws_cloudtrail" "remediation_cloudtrail" {
  name                          = "security-cloudtail"
  s3_bucket_name                = data.aws_s3_bucket.remediation_logs_bucket.id
  s3_key_prefix                 = "cloudtrail"
  is_multi_region_trail         = true
  include_global_service_events = true
  enable_log_file_validation    = true
}

# Ensure the logs bucket has the appropriate access controls
resource "aws_s3_bucket_acl" "remediation_logs_bucket_acl" {
  bucket = data.aws_s3_bucket.remediation_logs_bucket.id
  acl    = "private"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "remediation_logs_bucket_encryption" {
  bucket = data.aws_s3_bucket.remediation_logs_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Protect the logs bucket with S3 Object Lock and MFA Delete
resource "aws_s3_bucket_object_lock_configuration" "remediation_logs_bucket_lock" {
  bucket = data.aws_s3_bucket.remediation_logs_bucket.id

  rule {
    default_retention {
      mode = "GOVERNANCE"
      years = 7
    }
  }

  object_lock_enabled = "Enabled"
}

resource "aws_s3_bucket_versioning" "remediation_logs_bucket_versioning" {
  bucket = data.aws_s3_bucket.remediation_logs_bucket.id
  versioning_configuration {
    status = "Enabled"
    mfa_delete = "Enabled"
  }
}

# Ensure the CloudTrail logs bucket policy allows the CloudTrail service to write logs
data "aws_iam_policy_document" "remediation_logs_bucket_policy" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetBucketLocation",
      "s3:PutObject",
      "s3:PutObjectAcl"
    ]
    resources = [
      "${data.aws_s3_bucket.remediation_logs_bucket.arn}/*"
    ]
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
  }
}

resource "aws_s3_bucket_policy" "remediation_logs_bucket_policy" {
  bucket = data.aws_s3_bucket.remediation_logs_bucket.id
  policy = data.aws_iam_policy_document.remediation_logs_bucket_policy.json
}

# Look up the existing S3 bucket used for CloudTrail logs
data "aws_s3_bucket" "remediation_logs_bucket" {
  bucket = "my-cloudtrail-logs-bucket"
}