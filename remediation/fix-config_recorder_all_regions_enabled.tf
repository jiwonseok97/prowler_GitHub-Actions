# Create a new AWS Config Delivery Channel to deliver configuration snapshots and logs
resource "aws_config_delivery_channel" "remediation_config_delivery_channel" {
  name           = "remediation-config-delivery-channel"
  s3_bucket_name = "my-config-bucket"
}

# Create a new AWS Config Configuration Recorder to record resource configurations
resource "aws_config_configuration_recorder" "remediation_config_recorder" {
  name     = "remediation-config-recorder"
  role_arn = aws_iam_role.remediation_config_recorder_role.arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

# Create a new IAM role for the AWS Config Recorder
resource "aws_iam_role" "remediation_config_recorder_role" {
  name = "remediation-config-recorder-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
      }
    ]
  })
}

# Attach the required IAM policy to the Config Recorder role
resource "aws_iam_role_policy_attachment" "remediation_config_recorder_role_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSConfigRole"
  role       = aws_iam_role.remediation_config_recorder_role.name
}