# Update the Network ACL to remove the allow rule for TCP port 22 (SSH) from 0.0.0.0/0
resource "aws_network_acl_rule" "remediation_remove_ssh_ingress" {
  network_acl_id = "acl-0572e1ab82993bb20"
  rule_number    = 100
  egress         = false
  protocol       = "tcp"
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  from_port      = 22
  to_port        = 22
}

# Add a new Network ACL rule to allow SSH access from a trusted CIDR block
resource "aws_network_acl_rule" "remediation_allow_ssh_from_trusted" {
  network_acl_id = "acl-0572e1ab82993bb20"
  rule_number    = 200
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "10.0.0.0/16"
  from_port      = 22
  to_port        = 22
}
