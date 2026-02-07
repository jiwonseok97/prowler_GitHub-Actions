# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Create a Network Firewall policy
resource "aws_networkfirewall_firewall_policy" "default_policy" {
  name = "default-policy"

  firewall_policy {
    # Set the default action to "drop" to implement a "default-deny" posture
    default_action {
      type = "DROP"
    }

    # Add rules to allow only the required traffic
    rule_group {
      name     = "allow-required-traffic"
      priority = 1

      rules {
        # Example rule to allow SSH traffic from a specific IP range
        source_addresses = ["10.0.0.0/16"]
        source_ports     = ["22"]
        destination_ports = ["22"]
        protocols        = ["TCP"]
        action           = "ALLOW"
      }
    }
  }
}

# Create a Network Firewall logging configuration
resource "aws_cloudwatch_log_group" "network_firewall_logs" {
  name = "network-firewall-logs"
}

resource "aws_networkfirewall_logging_configuration" "default_logging" {
  firewall_arn = aws_networkfirewall_firewall.default_firewall.arn

  logging_configuration {
    log_destination_config {
      log_destination      = aws_cloudwatch_log_group.network_firewall_logs.name
      log_destination_type = "CloudWatchLogs"
    }

    # Enable logging for all event types
    log_type = "ALERT"
    log_type = "FLOW"
    log_type = "TRAFFIC"
  }
}

# Create a Network Firewall in the existing VPC
data "aws_vpc" "existing_vpc" {
  id = "vpc-0565167ce4f7cc871"
}

resource "aws_networkfirewall_firewall" "default_firewall" {
  name                = "default-firewall"
  firewall_policy_arn = aws_networkfirewall_firewall_policy.default_policy.arn
  vpc_id              = data.aws_vpc.existing_vpc.id
  subnet_mapping {
    subnet_id = data.aws_vpc.existing_vpc.default_subnet_id
  }
}


This Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Creates a Network Firewall policy with a `default-deny` posture and a rule group to allow only the required traffic (in this example, SSH traffic from a specific IP range).
3. Creates a CloudWatch log group and configures the Network Firewall to log all event types (alerts, flows, and traffic) to the log group.
4. Retrieves the existing VPC using a data source and creates a Network Firewall resource in the VPC, using the default subnet.