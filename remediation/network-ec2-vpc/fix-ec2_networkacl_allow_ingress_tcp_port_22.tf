#Update the Network ACL to remove the allow rule for TCP port 22 from 0.0.0.0/0
resource "aws_network_acl_rule" "remediation_remove_ssh_access" {
  network_acl_id = "acl-0572e1ab82993bb20"
  rule_number    = 100
  egress         = false
  protocol       = "tcp"
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  from_port      = 22
  to_port        = 22
}
