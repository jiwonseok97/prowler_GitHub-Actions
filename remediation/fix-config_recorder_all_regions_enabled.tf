# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Get the existing AWS Config Recorder
data "aws_config_configuration_recorder" "existing_recorder" {
  name = "config-recorder"
}

# Enable the AWS Config Recorder in all regions
resource "aws_config_configuration_recorder" "config_recorder" {
  name     = "config-recorder"
  role_arn = data.aws_config_configuration_recorder.existing_recorder.role_arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}