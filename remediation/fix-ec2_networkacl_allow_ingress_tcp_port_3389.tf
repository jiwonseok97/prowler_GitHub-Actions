# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Get the existing network ACL
data "aws_network_acl" "existing_nacl" {
  network_acl_id = "acl-0d23e762ebdfb131c"
}

# Create a new network ACL entry to deny ingress TCP port 3389 from 0.0.0.0/0
resource "aws_network_acl_rule" "deny_rdp_ingress" {
  network_acl_id = data.aws_network_acl.existing_nacl.id
  rule_number    = 100
  egress         = false
  protocol       = "tcp"
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  from_port      = 3389
  to_port        = 3389
}

# Add a comment to explain the purpose of the new network ACL rule
resource "aws_network_acl_rule" "comment_deny_rdp_ingress" {
  network_acl_id = data.aws_network_acl.existing_nacl.id
  rule_number    = 101
  egress         = false
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  to_port        = 0
  comments       = "Deny ingress TCP port 3389 (RDP) from 0.0.0.0/0"
}