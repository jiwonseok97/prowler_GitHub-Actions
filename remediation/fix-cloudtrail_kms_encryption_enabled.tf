# Modify the existing CloudTrail trail to enable SSE-KMS encryption using a customer-managed KMS key
resource "aws_cloudtrail" "remediation_security_cloudtail" {
  name = "security-cloudtail"
  s3_bucket_name                = "my-cloudtrail-bucket"
  s3_key_prefix                 = "cloudtrail"
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  kms_key_id                    = aws_kms_key.remediation_cloudtrail_kms_key.arn
}

# Create a customer-managed KMS key for CloudTrail log encryption
resource "aws_kms_key" "remediation_cloudtrail_kms_key" {
  description             = "Customer-managed KMS key for CloudTrail log encryption"
  deletion_window_in_days = 30
  enable_key_rotation     = true
}

# Attach a key policy to the KMS key to grant necessary permissions
resource "aws_kms_key_policy" "remediation_cloudtrail_kms_key_policy" {
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        Action = "kms:*",
        Resource = "*"
      },
      {
        Effect = "Allow",
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        },
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ],
        Resource = "*"
      }
    ]
  })
  key_id = aws_kms_key.remediation_cloudtrail_kms_key.key_id
}

# Ensure the S3 bucket used by CloudTrail has server-side encryption enabled
resource "aws_s3_bucket_server_side_encryption_configuration" "remediation_cloudtrail_bucket_encryption" {
  bucket = "my-cloudtrail-bucket"
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Ensure the S3 bucket used by CloudTrail has the correct ACL

resource "aws_s3_bucket_policy" "remediation_cloudtrail_bucket_policy" {
  bucket = "my-cloudtrail-bucket"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AWSCloudTrailAclCheck"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:GetBucketAcl"
        Resource  = "arn:aws:s3:::my-cloudtrail-bucket"
      },
      {
        Sid       = "AWSCloudTrailWrite"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = "arn:aws:s3:::my-cloudtrail-bucket/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}