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
  firewall_policy_name = "example-firewall-policy"
  subnet_mapping {
    subnet_id = "subnet-0123456789abcdef"
  }
}

# Create a new Network Firewall Firewall Policy
resource "aws_networkfirewall_firewall_policy" "example_firewall_policy" {
  name = "example-firewall-policy"

  # Configure the default action to 'drop' traffic
  default_action {
    type = "DROP"
  }

  # Add a rule to allow specific egress traffic
  rule_group {
    name = "example-rule-group"
    type = "STATELESS"
    rule_group_config {
      rules_source {
        stateless_rules_and_custom_actions {
          stateless_rule {
            priority = 100
            rule_definition {
              actions = ["PASS"]
              match_attributes {
                destination {
                  port_range {
                    from_port = 80
                    to_port   = 80
                  }
                  protocol = "TCP"
                }
              }
            }
          }
        }
      }
    }
  }
}


This Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Retrieves the existing VPC details using the `data.aws_vpc` data source.
3. Creates a new Network Firewall Firewall resource with the name `example-firewall`, associated with the existing VPC.
4. Creates a new Network Firewall Firewall Policy resource with the name `example-firewall-policy`.
5. Sets the default action for the firewall policy to `DROP` traffic.
6. Adds a rule group with a single stateless rule that allows TCP traffic on port 80.

This code should help address the security finding by deploying an AWS Network Firewall in the existing VPC and configuring a default-deny policy with a specific rule to allow the required egress traffic.