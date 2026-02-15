# Enable log file validation on the existing CloudTrail trail
resource "aws_cloudtrail" "remediation_security_cloudtail" {
  name                          = "security-cloudtail"
  s3_bucket_name                = var.s3_bucket_name
  s3_key_prefix                 = "cloudtrail-logs"
  is_multi_region_trail         = true
  include_global_service_events = true
  enable_log_file_validation    = true
}

# Ensure the S3 bucket has the appropriate permissions for CloudTrail logs

resource "aws_s3_bucket_server_side_encryption_configuration" "remediation_cloudtrail_logs_bucket_encryption" {
  bucket = var.s3_bucket_name

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Optionally, you can add an S3 bucket policy to further restrict access to the CloudTrail logs
resource "aws_s3_bucket_policy" "remediation_cloudtrail_logs_bucket_policy" {
  bucket = var.s3_bucket_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        },
        Action   = "s3:GetBucketAcl",
        Resource = "arn:aws:s3:::${var.s3_bucket_name}"
      },
      {
        Effect = "Allow",
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        },
        Action   = "s3:PutObject",
        Resource = "arn:aws:s3:::${var.s3_bucket_name}/cloudtrail-logs/*",
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket for CloudTrail logs"
  type        = string
}
