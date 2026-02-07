# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Get the existing VPC details
data "aws_vpc" "existing_vpc" {
  id = "vpc-0565167ce4f7cc871"
}

# Create a new Network Firewall Firewall
resource "aws_networkfirewall_firewall" "network_firewall" {
  name     = "my-network-firewall"
  vpc_id   = data.aws_vpc.existing_vpc.id
  subnets  = data.aws_vpc.existing_vpc.public_subnets
  firewall_policy_name = "my-network-firewall-policy"
}

# Create a new Network Firewall Firewall Policy
resource "aws_networkfirewall_firewall_policy" "network_firewall_policy" {
  name = "my-network-firewall-policy"

  # Set the default action to 'drop' to adopt a 'default-deny' posture
  default_action {
    type = "DROP"
  }

  # Add a rule to allow required egress traffic
  rule_group {
    name     = "my-rule-group"
    priority = 1

    rules = <<RULES
      # Allow outbound traffic to required destinations
      pass tcp any any -> 10.0.0.0/8 any (port:80,443; direction:outbound; sid:1000001;)
    RULES
  }
}

# Create a new Network Firewall Logging Configuration
resource "aws_networkfirewall_logging_configuration" "network_firewall_logging" {
  firewall_arn = aws_networkfirewall_firewall.network_firewall.arn

  logging_configuration {
    log_destination_config {
      log_destination = "my-s3-bucket"
      log_destination_type = "S3"
    }
    log_type = "FLOW"
  }
}


The provided Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Retrieves the existing VPC details using the `data.aws_vpc` data source.
3. Creates a new Network Firewall Firewall resource with the existing VPC details.
4. Creates a new Network Firewall Firewall Policy resource with a default action set to `DROP` to adopt a `default-deny` posture.
5. Adds a rule group to the Firewall Policy to allow required outbound traffic to specific destinations (port 80 and 443).
6. Creates a new Network Firewall Logging Configuration resource to enable logging of network traffic to an S3 bucket.