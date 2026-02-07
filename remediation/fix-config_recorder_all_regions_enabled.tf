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
  for_each = toset(data.aws_regions.all.names)

  name     = "config-recorder"
  role_arn = data.aws_iam_role.config_role.arn
  status {
    name       = "config-recorder"
    state      = "ENABLED"
    input_parameters = <<EOF
{
  "recordingGroup": {
    "allSupported": true,
    "includeGlobalResourceTypes": true
  }
}
EOF
  }

  depends_on = [
    data.aws_iam_role.config_role
  ]
}

# Get all available AWS regions
data "aws_regions" "all" {}

# Get the existing AWS Config IAM role
data "aws_iam_role" "config_role" {
  name = "config-role"
}