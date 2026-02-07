# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Get the existing AWS Config Recorder resource
data "aws_config_configuration_recorder" "existing_recorder" {
  name     = "config-recorder"
  provider = aws.ap-northeast-2
}

# Enable AWS Config in all regions
resource "aws_config_configuration_recorder" "config_recorder" {
  name     = "config-recorder"
  role_arn = data.aws_config_configuration_recorder.existing_recorder.role_arn
  provider = aws.ap-northeast-2

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}


The provided Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Retrieves the existing AWS Config Recorder resource using the `data` source.
3. Creates a new `aws_config_configuration_recorder` resource to enable AWS Config in all regions and include global resource types.
4. The `role_arn` is set to the existing recorder's role ARN to ensure the necessary permissions are in place.