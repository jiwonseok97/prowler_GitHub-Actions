#
# Restrict RDP access to the network ACL
#
resource "aws_network_acl_rule" "remediation_rdp_ingress_deny" {
  network_acl_id = "acl-0572e1ab82993bb20"
  rule_number    = 100
  egress         = false
  protocol       = "tcp"
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  from_port      = 3389
  to_port        = 3389
}

#
# Prefer bastion hosts or Session Manager over direct RDP
#
# Add your bastion host or Session Manager configuration here
