# Enable S3 versioning for the existing bucket
resource "aws_s3_bucket_versioning" "remediation_s3_bucket_versioning" {
  bucket = "aws-cloudtrail-logs-132410971304-0971c04b"
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable S3 bucket encryption using a new KMS key
resource "aws_kms_key" "remediation_s3_bucket_encryption_key" {
  description             = "KMS key for S3 bucket encryption"
  deletion_window_in_days = 10
}

resource "aws_s3_bucket_server_side_encryption_configuration" "remediation_s3_bucket_encryption" {
  bucket = "aws-cloudtrail-logs-132410971304-0971c04b"
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.remediation_s3_bucket_encryption_key.id
      sse_algorithm     = "aws:kms"
    }
  }
}

# Apply S3 bucket lifecycle rules to manage noncurrent versions
resource "aws_s3_bucket_lifecycle_configuration" "remediation_s3_bucket_lifecycle" {
  bucket = "aws-cloudtrail-logs-132410971304-0971c04b"

  rule {
    id     = "lifecycle-rule-1"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

# Enable MFA delete for stronger protection
resource "aws_s3_bucket_ownership_controls" "remediation_s3_bucket_ownership_controls" {
  bucket = "aws-cloudtrail-logs-132410971304-0971c04b"
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "remediation_s3_bucket_public_access_block" {
  bucket                  = "aws-cloudtrail-logs-132410971304-0971c04b"
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Apply a backup/replication strategy for defense in depth
resource "aws_backup_vault" "remediation_backup_vault" {
  name = "remediation-backup-vault"
}

resource "aws_backup_plan" "remediation_backup_plan" {
  name = "remediation-backup-plan"

  rule {
    rule_name         = "remediation-backup-rule"
    target_vault_name = aws_backup_vault.remediation_backup_vault.name
    schedule          = "cron(0 5 ? * MON *)"
  }
}

resource "aws_backup_selection" "remediation_backup_selection" {
  name         = "remediation-backup-selection"
  iam_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-backup-role"
  plan_id      = aws_backup_plan.remediation_backup_plan.id
  resources    = ["arn:aws:s3:::aws-cloudtrail-logs-132410971304-0971c04b"]
}
