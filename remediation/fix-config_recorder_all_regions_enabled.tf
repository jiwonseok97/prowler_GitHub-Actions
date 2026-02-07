# Configure the AWS provider for the ap-northeast-2 region

# Get the existing AWS Config Recorder resource
data "aws_config_configuration_recorder" "existing_recorder" {
  name     = "config-recorder"
  provider = aws
}

# Enable AWS Config in all regions with continuous recording
resource "aws_config_configuration_recorder" "config_recorder" {
  name     = "config-recorder"
  role_arn = data.aws_config_configuration_recorder.existing_recorder.role_arn
  
  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}