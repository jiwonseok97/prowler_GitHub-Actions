# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Create a Network Firewall policy
resource "aws_networkfirewall_firewall_policy" "default_policy" {
  name = "default-policy"

  # Set the default action to 'drop' to implement a 'default-deny' posture
  default_action {
    type = "DROP"
  }

  # Add a rule group to allow only required egress traffic
  rule_group {
    name     = "egress-rule-group"
    priority = 1

    rules {
      # Example rule to allow SSH traffic to a specific destination
      source_addresses = ["0.0.0.0/0"]
      source_ports     = ["any"]
      destination_addresses = ["10.0.1.100/32"]
      destination_ports = ["22"]
      protocols        = ["tcp"]
      action           = "ALLOW"
    }
  }
}

# Create a Network Firewall
resource "aws_networkfirewall_firewall" "default_firewall" {
  name                = "default-firewall"
  firewall_policy_arn = aws_networkfirewall_firewall_policy.default_policy.arn
  vpc_id              = "vpc-0565167ce4f7cc871" # Use data source to reference existing VPC
  subnet_mapping {
    subnet_id = "subnet-0123456789abcdef" # Use data source to reference existing subnet
  }
}

# Enable logging for the Network Firewall
resource "aws_cloudwatch_log_group" "network_firewall_logs" {
  name = "network-firewall-logs"
}

resource "aws_networkfirewall_logging_configuration" "default_logging" {
  firewall_arn = aws_networkfirewall_firewall.default_firewall.arn
  log_destination_config {
    log_destination      = aws_cloudwatch_log_group.network_firewall_logs.name
    log_destination_type = "CloudWatchLogs"
  }
}


This Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Creates a Network Firewall policy with a `default-deny` posture, where the default action is to `DROP` all traffic.
3. Adds a rule group to the policy to allow only required egress traffic, in this example, SSH traffic to a specific destination.
4. Creates a Network Firewall resource and associates it with the existing VPC and a subnet.
5. Enables logging for the Network Firewall, sending logs to a CloudWatch log group.