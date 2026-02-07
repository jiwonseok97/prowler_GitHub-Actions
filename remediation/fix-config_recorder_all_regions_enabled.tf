# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

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


This Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Retrieves the existing AWS Config Recorder resource using the `data` source.
3. Creates a new `aws_config_configuration_recorder` resource to enable AWS Config in all regions with continuous recording.
   - The `name` attribute is set to `"config-recorder"`.
   - The `role_arn` attribute is set to the role ARN of the existing recorder, retrieved using the `data` source.
   - The `recording_group` block is configured to include all supported resource types and global resource types.