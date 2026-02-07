# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Create a Network Firewall policy
resource "aws_networkfirewall_firewall_policy" "default_policy" {
  name = "default-policy"

  firewall_policy {
    # Set the default action to "drop" (default-deny posture)
    default_action {
      type = "DROP"
    }

    # Add logging configuration to monitor network traffic
    logging_configuration {
      log_destination_config {
        log_destination = "arn:aws:logs:ap-northeast-2:132410971304:log-group:/aws/network-firewall/logs"
        log_destination_type = "CloudWatchLogs"
      }
      log_type = "FLOW"
    }
  }
}

# Create a Network Firewall
resource "aws_networkfirewall_firewall" "default_firewall" {
  name                = "default-firewall"
  firewall_policy_arn = aws_networkfirewall_firewall_policy.default_policy.arn
  vpc_id              = "vpc-0565167ce4f7cc871"
  subnet_mapping {
    subnet_id = "subnet-0123456789abcdef"
  }
}


The provided Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Creates a Network Firewall policy with a default action of "DROP" (default-deny posture).
3. Enables logging for the Network Firewall to monitor network traffic.
4. Creates a Network Firewall resource and associates it with the VPC `vpc-0565167ce4f7cc871` and a subnet `subnet-0123456789abcdef`.

This code should address the security finding by deploying the AWS Network Firewall in the specified VPC, adopting a default-deny posture, and enabling logging for network traffic monitoring.