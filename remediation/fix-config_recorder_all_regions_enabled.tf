# Enable AWS Config in the ap-northeast-2 region
resource "aws_config_configuration_recorder" "remediation_config_recorder" {
  name = "config-recorder"
  role_arn = data.aws_iam_role.remediation_config_recorder_role.arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

# Create the IAM role for the AWS Config recorder
data "aws_iam_role" "remediation_config_recorder_role" {
  name = "config-recorder-role"
}

# Attach the required policy to the IAM role