# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Get the existing AWS Config recorder
data "aws_config_configuration_recorder" "existing_recorder" {
  name = "config-recorder"
}

# Enable the AWS Config recorder in all regions
resource "aws_config_configuration_recorder" "config_recorder" {
  for_each = toset(data.aws_regions.all.names)

  name     = "config-recorder"
  role_arn = data.aws_iam_role.config_role.arn
  status {
    name       = "config-recorder"
    input_parameters = <<EOF
{
  "recordingGroup": {
    "allSupported": true,
    "includeGlobalResourceTypes": true
  }
}
EOF
    is_enabled = true
    account_id = data.aws_caller_identity.current.account_id
    region = each.value
  }
}

# Get the existing IAM role for AWS Config
data "aws_iam_role" "config_role" {
  name = "config-role"
}

# Get the list of all AWS regions
data "aws_regions" "all" {}

# Get the current AWS account ID
data "aws_caller_identity" "current" {}