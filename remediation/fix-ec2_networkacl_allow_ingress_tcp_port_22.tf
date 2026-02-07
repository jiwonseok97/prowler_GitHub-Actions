# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Get the existing Network ACL
data "aws_network_acl" "existing_nacl" {
  network_acl_id = "acl-0d23e762ebdfb131c"
}

# Create a new Network ACL entry to deny ingress TCP port 22 from 0.0.0.0/0
resource "aws_network_acl_rule" "deny_ssh_from_internet" {
  network_acl_id = data.aws_network_acl.existing_nacl.id
  rule_number    = 100
  egress         = false
  protocol       = "tcp"
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  from_port      = 22
  to_port        = 22
}

# Add a comment to explain the purpose of the new Network ACL rule
resource "aws_network_acl_rule" "comment_deny_ssh_from_internet" {
  network_acl_id = data.aws_network_acl.existing_nacl.id
  rule_number    = 101
  egress         = false
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  to_port        = 0
  comments       = "Deny SSH access from the internet"
}