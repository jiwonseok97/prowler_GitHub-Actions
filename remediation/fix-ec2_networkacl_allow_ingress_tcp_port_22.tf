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


This Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Retrieves the existing Network ACL using the `data` source `aws_network_acl`.
3. Creates a new Network ACL rule to deny ingress TCP port 22 (SSH) from `0.0.0.0/0` (the entire internet) using the `aws_network_acl_rule` resource.

This should address the security finding by restricting SSH access to the network ACL.