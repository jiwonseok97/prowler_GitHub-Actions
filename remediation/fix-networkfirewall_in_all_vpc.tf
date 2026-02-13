# AWS Network Firewall baseline snippet
# Firewall policy + rule group + firewall in VPC

resource "aws_networkfirewall_rule_group" "remediation_stateless_rule_group" {
  capacity = 100
  name = "remediation-stateless-drop-ssh"
  type     = "STATELESS"
  rule_group {
    rules_source {
      stateless_rules_and_custom_actions {
        stateless_rule {
          priority = 1
          rule_definition {
            actions = ["aws:drop"]
            match_attributes {
              protocols = [6]
              source {
                address_definition = "0.0.0.0/0"
              }
              destination {
                address_definition = "0.0.0.0/0"
              }
              destination_port {
                from_port = 22
                to_port   = 22
              }
            }
          }
        }
      }
    }
  }
}

resource "aws_networkfirewall_firewall_policy" "remediation_firewall_policy" {
  name = "remediation-firewall-policy"
  firewall_policy {
    stateless_default_actions          = ["aws:forward_to_sfe"]
    stateless_fragment_default_actions = ["aws:forward_to_sfe"]
    stateless_rule_group_reference {
      priority     = 1
      resource_arn = aws_networkfirewall_rule_group.remediation_stateless_rule_group.arn
    }
  }
}

resource "aws_networkfirewall_firewall" "remediation_firewall" {
  name = "remediation-network-firewall"
  firewall_policy_arn = aws_networkfirewall_firewall_policy.remediation_firewall_policy.arn
  vpc_id              = var.vpc_id

  subnet_mapping {
    subnet_id = var.firewall_subnet_id
  }
}

variable "vpc_id" {
  description = "VPC ID for Network Firewall"
  type        = string
}

variable "firewall_subnet_id" {
  description = "Subnet ID for Network Firewall endpoint"
  type        = string
}