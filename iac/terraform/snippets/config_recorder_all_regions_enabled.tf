# AWS Config recorder baseline (all regions)

# S3 bucket for configuration snapshots
resource "aws_s3_bucket" "remediation_config_bucket" {
  bucket = "remediation-config-${data.aws_caller_identity.current.account_id}"
}

resource "aws_s3_bucket_public_access_block" "remediation_config_bucket_public_access" {
  bucket                  = aws_s3_bucket.remediation_config_bucket.id
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

# IAM role for AWS Config
resource "aws_iam_role" "remediation_config_role" {
  name = "remediation-config-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "remediation_config_role_attachment" {
  role       = aws_iam_role.remediation_config_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSConfigRole"
}

# Configuration recorder (all regions)
resource "aws_config_configuration_recorder" "remediation_config_recorder" {
  name     = "remediation-config-recorder"
  role_arn = aws_iam_role.remediation_config_role.arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

# Delivery channel for snapshots
resource "aws_config_delivery_channel" "remediation_config_delivery_channel" {
  name           = "remediation-config-delivery-channel"
  s3_bucket_name = aws_s3_bucket.remediation_config_bucket.bucket

  depends_on = [aws_config_configuration_recorder.remediation_config_recorder]
}

# Enable recorder
resource "aws_config_configuration_recorder_status" "remediation_config_recorder_status" {
  name       = aws_config_configuration_recorder.remediation_config_recorder.name
  is_enabled = true

  depends_on = [aws_config_delivery_channel.remediation_config_delivery_channel]
}
