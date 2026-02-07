# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Get the existing network ACL
data "aws_network_acl" "existing_nacl" {
  network_acl_id = "acl-0d23e762ebdfb131c"
}

# Create a new network ACL entry to deny TCP port 3389 from 0.0.0.0/0
resource "aws_network_acl_rule" "deny_rdp_from_internet" {
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
3. Creates a new network ACL rule using the `aws_network_acl_rule` resource to deny TCP port 3389 (RDP) from the internet (`0.0.0.0/0`).

This should address the security finding by restricting access to TCP port 3389 from the internet, as recommended in the finding.