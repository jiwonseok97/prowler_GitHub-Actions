#Update the Network ACL to remove the allow rule for TCP port 3389 from 0.0.0.0/0
resource "aws_network_acl_rule" "remediation_remove_rdp_ingress" {
  network_acl_id = "acl-0d23e762ebdfb131c"
  rule_number    = 100
  egress         = false
  protocol       = "tcp"
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  from_port      = 3389
  to_port        = 3389
}

#Add a new Network ACL rule to allow RDP access only from a specific IP range
resource "aws_network_acl_rule" "remediation_allow_rdp_from_admin_ips" {
  network_acl_id = "acl-0d23e762ebdfb131c"
  rule_number    = 200
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "10.0.0.0/16"
  from_port      = 3389
  to_port        = 3389
}
