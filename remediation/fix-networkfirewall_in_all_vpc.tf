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
    type     = "STATEFUL"

    rules = <<RULES
      pass tcp any any -> any any (msg:"Allow HTTP traffic"; flow:established,to_server; app:http;)
      pass tcp any any -> any any (msg:"Allow HTTPS traffic"; flow:established,to_server; app:https;)
    RULES
  }
}

# Associate the Firewall Policy with the Firewall
resource "aws_networkfirewall_firewall_policy_association" "example_firewall_policy_association" {
  firewall_name       = aws_networkfirewall_firewall.example_firewall.name
  firewall_policy_arn = aws_networkfirewall_firewall_policy.example_firewall_policy.arn
}


This Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Retrieves the details of the existing VPC using the `data.aws_vpc` data source.
3. Creates a new Network Firewall Firewall named `example-firewall` in the existing VPC, using the public subnets.
4. Creates a new Network Firewall Firewall Policy named `example-firewall-policy` with a default action of `DROP` to adopt a `default-deny` posture.
5. Adds a rule group to the Firewall Policy to allow HTTP and HTTPS traffic.
6. Associates the Firewall Policy with the Firewall.

This should address the security finding by deploying an AWS Network Firewall in the existing VPC, with a `default-deny` posture and a rule to allow required egress traffic.