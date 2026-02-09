# Enable AWS Config recorder in ap-northeast-2 region
resource "aws_config_configuration_recorder" "remediation_config_recorder" {
  name     = "remediation-config-recorder"
  role_arn = aws_iam_role.remediation_config_recorder_role.arn
  
  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

# Create IAM role for AWS Config recorder
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
      },
    ]
  })
}

# Attach required IAM policy to the role
resource "aws_iam_role_policy_attachment" "remediation_config_recorder_role_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSConfigRole"
  role       = aws_iam_role.remediation_config_recorder_role.name
}

# Configure AWS provider for ap-northeast-2 region