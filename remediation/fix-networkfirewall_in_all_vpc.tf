# Create a Network Firewall Firewall and associated resources
resource "aws_networkfirewall_firewall" "remediation_network_firewall" {
  name           = "remediation-network-firewall"
  vpc_id         = "vpc-0565167ce4f7cc871"
  firewall_policy_arn = aws_networkfirewall_firewall_policy.remediation_network_firewall_policy.arn
}

resource "aws_networkfirewall_firewall_policy" "remediation_network_firewall_policy" {
  name = "remediation-network-firewall-policy"

  firewall_policy {
    stateless_default_actions          = ["aws:pass"]
    stateless_fragment_default_actions = ["aws:pass"]
    stateful_rule_group_reference {
      resource_arn = aws_networkfirewall_rule_group.remediation_network_firewall_rule_group.arn
    }
  }
}

resource "aws_networkfirewall_rule_group" "remediation_network_firewall_rule_group" {
  capacity = 100
  name     = "remediation-network-firewall-rule-group"
  type     = "STATEFUL"

  rules = <<EOF
  # Example stateful rule to block SSH access from untrusted IP ranges
  pass tcp from any to any port 22 stateful (
    sid:1000; 
    direction:FORWARD; 
    action:PASS;
    tcp.flags:S,A/S,A;
    src.ip:10.0.0.0/8,172.16.0.0/12,192.168.0.0/16;
  )
EOF
}