# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Get the existing Network ACL
data "aws_network_acl" "existing_nacl" {
  network_acl_id = "acl-0d23e762ebdfb131c"
}

# Create a new Network ACL entry to deny ingress TCP port 22 from 0.0.0.0/0
resource "aws_network_acl_rule" "deny_ssh_ingress" {
  network_acl_id = data.aws_network_acl.existing_nacl.id
  rule_number    = 100
  egress         = false
  protocol       = "tcp"
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  from_port      = 22
  to_port        = 22
}

# Add a comment to explain the purpose of the new rule
resource "aws_network_acl_rule" "comment_deny_ssh_ingress" {
  network_acl_id = data.aws_network_acl.existing_nacl.id
  rule_number    = 101
  egress         = false
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  to_port        = 0
  comments       = "Deny SSH ingress from 0.0.0.0/0"
}


The provided Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Retrieves the existing Network ACL using the `data.aws_network_acl` data source.
3. Creates a new Network ACL rule to deny ingress TCP port 22 (SSH) from `0.0.0.0/0` (the entire internet).
4. Adds a comment to the Network ACL to explain the purpose of the new rule.

This code addresses the security finding by restricting SSH access to the network ACL, following the recommendation to "not allow `0.0.0.0/0` to `TCP 22`".