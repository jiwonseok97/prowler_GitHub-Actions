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
    stateless_fragment_default_actions = ["drop"]
    stateful_default_actions = ["pass"]
  }
}

# Create a Network Firewall logging configuration
resource "aws_networkfirewall_logging_configuration" "default_logging" {
  firewall_arn = aws_networkfirewall_firewall.default_firewall.arn

  # Enable logging for all traffic
  log_destination_config {
    log_destination = {
      bucketname = "my-network-firewall-logs"
      prefix     = "default-firewall"
    }
    log_destination_type = "s3"
    log_type            = "FLOW"
  }
}

# Create a Network Firewall for the existing VPC
resource "aws_networkfirewall_firewall" "default_firewall" {
  name                = "default-firewall"
  firewall_policy_arn = aws_networkfirewall_firewall_policy.default_policy.arn
  vpc_id              = "vpc-0565167ce4f7cc871"
  subnet_mapping {
    subnet_id = "subnet-0123456789abcdef"
  }
}


This Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Creates a Network Firewall policy with a `default-deny` posture, where the default action is to `drop` all traffic.
3. Creates a Network Firewall logging configuration to send flow logs to an S3 bucket.
4. Creates a Network Firewall resource for the existing VPC, using the default policy and subnet mapping.