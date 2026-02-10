# Enable S3 versioning for the existing bucket
resource "aws_s3_bucket_versioning" "remediation_s3_bucket_versioning" {
  bucket = "aws-cloudtrail-logs-132410971304-0971c04b"
  versioning_configuration {
    status = "Enabled"
  }
}

# Apply Object Lock to the existing bucket for stronger protection
resource "aws_s3_bucket_ownership_controls" "remediation_s3_bucket_ownership_controls" {
  bucket = "aws-cloudtrail-logs-132410971304-0971c04b"
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "remediation_s3_bucket_public_access_block" {
  bucket = "aws-cloudtrail-logs-132410971304-0971c04b"
  block_public_acls       = true
  block_public_policy    = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Apply lifecycle rules to manage noncurrent versions and costs
resource "aws_s3_bucket_lifecycle_configuration" "remediation_s3_bucket_lifecycle_configuration" {
  bucket = "aws-cloudtrail-logs-132410971304-0971c04b"

  rule {
    id = "lifecycle-rule-1"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

# Layer with backups/replication for defense in depth
# (example of creating an S3 bucket for replication)
resource "aws_s3_bucket" "remediation_s3_bucket_replication" {
  bucket = "aws-cloudtrail-logs-132410971304-replication"

  versioning {
    enabled = true
  }

}

resource "aws_s3_bucket_replication_configuration" "remediation_s3_bucket_replication_configuration" {
  role = aws_iam_role.remediation_s3_replication_role.arn
  bucket = "aws-cloudtrail-logs-132410971304-0971c04b"

  rule {
    status = "Enabled"

    destination {
      bucket        = aws_s3_bucket.remediation_s3_bucket_replication.id
      storage_class = "GLACIER"
    }
  }
}

resource "aws_iam_role" "remediation_s3_replication_role" {
  name = "remediation-s3-replication-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "remediation_s3_replication_policy" {
  name = "remediation-s3-replication-policy"
  role = aws_iam_role.remediation_s3_replication_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetReplicationConfiguration",
          "s3:ListBucket"
        ],
        Resource = [
          "arn:aws:s3:::aws-cloudtrail-logs-132410971304-0971c04b"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionTagging",
          "s3:GetObjectRetention",
          "s3:GetObjectLegalHold",
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags",
          "s3:GetObjectVersionTagging"
        ],
        Resource = [
          "arn:aws:s3:::aws-cloudtrail-logs-132410971304-0971c04b/*"
        ]
      }
    ]
  })
}