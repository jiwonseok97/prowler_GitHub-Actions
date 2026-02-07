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


This Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Retrieves the existing network ACL using the `data` source `aws_network_acl`.
3. Creates a new network ACL rule using the `aws_network_acl_rule` resource to deny ingress TCP traffic on port 3389 (RDP) from the `0.0.0.0/0` CIDR block.

This will enforce the recommendation to not allow `TCP 3389` from `0.0.0.0/0` in the network ACL, restricting RDP access to the specified resource.