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

      rules = <<RULES
      # Add your firewall rules here
      RULES
    }
  }
}

# Create a Network Firewall
resource "aws_networkfirewall_firewall" "vpc_firewall" {
  name                = "vpc-firewall"
  firewall_policy_arn = aws_networkfirewall_firewall_policy.default_policy.arn
  vpc_id              = "vpc-0565167ce4f7cc871" # Replace with the VPC ID from the finding
  subnet_mapping {
    # Add subnet IDs where the Network Firewall should be deployed
    subnet_id = "subnet-0123456789abcdef"
  }
}

# Enable logging for the Network Firewall
resource "aws_cloudwatch_log_group" "network_firewall_logs" {
  name = "network-firewall-logs"
}

resource "aws_networkfirewall_logging_configuration" "network_firewall_logging" {
  firewall_arn = aws_networkfirewall_firewall.vpc_firewall.arn
  log_group_name = aws_cloudwatch_log_group.network_firewall_logs.name

  logging_configuration {
    log_destination_config {
      log_destination = aws_cloudwatch_log_group.network_firewall_logs.name
      log_destination_type = "CloudWatchLogs"
    }
  }
}


This Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Creates a Network Firewall policy with a "default-deny" posture, allowing only the required traffic.
3. Creates a Network Firewall resource and associates it with the VPC specified in the finding.
4. Enables logging for the Network Firewall, sending logs to a CloudWatch log group.

You can customize the firewall rules in the `rule_group` block and the subnet mapping to fit your specific requirements.