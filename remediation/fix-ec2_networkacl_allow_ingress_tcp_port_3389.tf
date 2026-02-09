# Create a new network ACL to replace the existing one
resource "aws_network_acl" "remediation_network_acl" {
  vpc_id = data.aws_vpc.current.id
}

# Add a new rule to deny ingress TCP port 3389 from 0.0.0.0/0
resource "aws_network_acl_rule" "remediation_deny_rdp_ingress" {
  network_acl_id = aws_network_acl.remediation_network_acl.id
  rule_number    = 100
  egress         = false
  protocol       = "tcp"
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  from_port      = 3389
  to_port        = 3389
}

# Add a new rule to allow ingress TCP port 22 (SSH) from a specific IP range
resource "aws_network_acl_rule" "remediation_allow_ssh_ingress" {
  network_acl_id = aws_network_acl.remediation_network_acl.id
  rule_number    = 200
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "192.168.0.0/16"
  from_port      = 22
  to_port        = 22
}

data "aws_vpc" "current" {
  default = true
}