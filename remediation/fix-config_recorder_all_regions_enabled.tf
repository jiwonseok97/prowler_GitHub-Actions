# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Get the existing AWS Config recorder
data "aws_config_configuration_recorder" "existing_recorder" {
  name = "config-recorder"
}

# Enable AWS Config in all regions with continuous recording
resource "aws_config_configuration_recorder" "config_recorder" {
  for_each = toset(data.aws_regions.all.names)

  name     = "config-recorder"
  role_arn = data.aws_iam_role.config_role.arn
  
  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }

  depends_on = [
    data.aws_iam_role.config_role
  ]
}

# Get all available AWS regions
data "aws_regions" "all" {}

# Get the existing AWS Config role
data "aws_iam_role" "config_role" {
  name = "config-role"
}