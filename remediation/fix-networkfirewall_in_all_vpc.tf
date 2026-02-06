# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Create a Network Firewall policy
resource "aws_networkfirewall_firewall_policy" "default_policy" {
  name = "default-policy"

  # Set the default action to "drop" to implement a "default-deny" posture
  firewall_policy {
    stateless_default_actions = ["drop"]
    stateless_engine_options {
      rule_order = "default_action_order"
    }
  }
}

# Create a Network Firewall logging configuration
resource "aws_networkfirewall_logging_configuration" "default_logging" {
  firewall_arn = aws_networkfirewall_firewall.default_firewall.arn

  # Enable logging for all event types
  log_destination_config {
    log_destination = {
      name = "cloudwatch-log-group"
      type = "CloudWatchLogs"
    }
    log_destination_type = "CloudWatchLogs"
    log_type            = "ALERT"
  }
  log_type = "ALERT"
}

# Create a Network Firewall for the existing VPC
resource "aws_networkfirewall_firewall" "default_firewall" {
  name                = "default-firewall"
  firewall_policy_arn = aws_networkfirewall_firewall_policy.default_policy.arn
  vpc_id              = data.aws_vpc.existing_vpc.id
  subnet_mapping {
    subnet_id = data.aws_subnet_ids.existing_vpc_subnets.ids[0]
  }
}

# Use a data source to reference the existing VPC
data "aws_vpc" "existing_vpc" {
  id = "vpc-0565167ce4f7cc871"
}

# Use a data source to reference the existing subnets in the VPC
data "aws_subnet_ids" "existing_vpc_subnets" {
  vpc_id = data.aws_vpc.existing_vpc.id
}


This Terraform code creates the following resources:

1. A Network Firewall policy with a "default-deny" posture, where the default action is set to "drop".
2. A Network Firewall logging configuration that sends all alert logs to a CloudWatch log group.
3. A Network Firewall resource that is attached to the existing VPC, using the default policy and the first subnet in the VPC.
4. Data sources to reference the existing VPC and its subnets.

The goal of this code is to deploy the AWS Network Firewall in the existing VPC, following the recommended "default-deny" and "least-privilege" security practices.