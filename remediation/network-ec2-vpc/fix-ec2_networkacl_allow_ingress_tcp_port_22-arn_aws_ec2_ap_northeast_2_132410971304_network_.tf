# Modify the existing Network ACL to remove the allow rule for TCP port 22 from 0.0.0.0/0
resource "aws_network_acl_rule" "remediation_remove_ssh_access" {
  network_acl_id = "acl-0d23e762ebdfb131c"
  rule_number    = 100
  egress         = false
  protocol       = "tcp"
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  from_port      = 22
  to_port        = 22
}

# Add a new Network ACL rule to allow SSH access only from trusted sources
resource "aws_network_acl_rule" "remediation_allow_ssh_from_trusted" {
  network_acl_id = "acl-0d23e762ebdfb131c"
  rule_number    = 200
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "10.0.0.0/8"
  from_port      = 22
  to_port        = 22
}
