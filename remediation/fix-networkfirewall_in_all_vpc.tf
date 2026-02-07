# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Get the existing VPC details
data "aws_vpc" "existing_vpc" {
  id = "vpc-0565167ce4f7cc871"
}

# Create a new Network Firewall Firewall
resource "aws_networkfirewall_firewall" "example_firewall" {
  name     = "example-firewall"
  vpc_id   = data.aws_vpc.existing_vpc.id
  subnets  = data.aws_vpc.existing_vpc.public_subnets
  firewall_policy_name = "example-firewall-policy"
}

# Create a new Network Firewall Firewall Policy
resource "aws_networkfirewall_firewall_policy" "example_firewall_policy" {
  name = "example-firewall-policy"

  # Set the default action to 'drop' to adopt a 'default-deny' posture
  default_action {
    type = "DROP"
  }

  # Add a rule to allow required egress traffic
  rule_group {
    name     = "example-rule-group"
    priority = 1

    rules = <<RULES
      # Allow HTTPS traffic to example.com
      action: PASS
      source_addresses: ["0.0.0.0/0"]
      destination_addresses: ["example.com"]
      destination_ports: ["443"]
      protocols: ["TCP"]
    RULES
  }

  # Enable logging for the firewall policy
  logging_configuration {
    log_destination_config {
      log_destination = "arn:aws:logs:ap-northeast-2:132410971304:log-group:/aws/network-firewall/example-firewall"
      log_destination_type = "CloudWatchLogs"
    }
    log_type = "FLOW"
  }
}


This Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Retrieves the existing VPC details using the `data.aws_vpc` data source.
3. Creates a new Network Firewall Firewall resource, associating it with the existing VPC.
4. Creates a new Network Firewall Firewall Policy resource, which sets the default action to `DROP` to adopt a `default-deny` posture.
5. Adds a rule to the firewall policy to allow HTTPS traffic to `example.com`.
6. Enables logging for the firewall policy, sending the logs to a CloudWatch Logs log group.

This code should help address the security finding by deploying an AWS Network Firewall in the existing VPC and configuring a firewall policy with a `default-deny` posture and a rule to allow the required egress traffic.