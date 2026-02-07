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
      name = "default-log-destination"
      type = "S3"
    }
    log_destination_type = "S3"
    log_type            = "ALERT"
  }
  log_type = "FLOW"
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


This Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Creates a Network Firewall policy with a default action of "drop" to implement a "default-deny" posture.
3. Creates a Network Firewall logging configuration to enable logging for all event types and store the logs in an S3 bucket.
4. Creates a Network Firewall for the existing VPC, using the default policy and the first subnet in the VPC.
5. Uses data sources to reference the existing VPC and its subnets, so that the Network Firewall can be deployed in the correct VPC.