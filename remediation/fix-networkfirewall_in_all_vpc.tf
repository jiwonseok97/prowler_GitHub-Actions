# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Create a Network Firewall policy
resource "aws_networkfirewall_firewall_policy" "default_policy" {
  name = "default-policy"

  firewall_policy {
    # Set the default action to "drop" (deny)
    default_action {
      type = "DROP"
    }

    # Add logging configuration
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


This Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Creates a Network Firewall policy with a default action of "DROP" (deny) and enables logging to CloudWatch Logs.
3. Creates a Network Firewall resource and associates it with the VPC `vpc-0565167ce4f7cc871` and a subnet `subnet-0123456789abcdef`.

The Network Firewall will be deployed in the specified VPC, and all traffic will be inspected and filtered according to the default "DROP" policy. You can further customize the firewall policy by adding specific rules to allow or deny traffic based on your requirements.