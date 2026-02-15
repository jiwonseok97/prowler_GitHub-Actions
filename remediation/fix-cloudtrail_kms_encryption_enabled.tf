# Modify the existing CloudTrail trail to enable encryption with a customer-managed KMS key
resource "aws_cloudtrail" "remediation_security_cloudtail" {
  name = "security-cloudtail"
  s3_bucket_name                = var.s3_bucket_name
  s3_key_prefix                 = "cloudtrail-logs"
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  kms_key_id                    = aws_kms_key.remediation_cloudtrail_kms_key.arn
}

# Create a customer-managed KMS key for encrypting CloudTrail logs
resource "aws_kms_key" "remediation_cloudtrail_kms_key" {
  description             = "Customer-managed KMS key for CloudTrail log encryption"
  deletion_window_in_days = 30
  enable_key_rotation     = true
}

# Grant the CloudTrail service the necessary permissions to use the KMS key
resource "aws_kms_key_policy" "remediation_cloudtrail_kms_key_policy" {
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
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
      },
      {
        Effect = "Allow",
        Principal = {
          AWS = data.aws_caller_identity.current.arn
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


variable "s3_bucket_name" {
  type        = string
  description = "Name of the S3 bucket where CloudTrail logs are stored"
}