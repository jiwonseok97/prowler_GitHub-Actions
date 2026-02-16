# Modify the existing Network ACL to remove the ingress rule allowing TCP port 3389 from 0.0.0.0/0
resource "aws_network_acl" "remediation_network_acl" {
  vpc_id = var.vpc_id
  subnet_ids = data.aws_subnets.existing_subnets.ids

  ingress {
    from_port  = 0
    to_port    = 0
    rule_no    = 100
    action     = "allow"
    protocol   = "-1"
    cidr_block = "0.0.0.0/0"
  }

  egress {
    from_port  = 0
    to_port    = 0
    rule_no    = 100
    action     = "allow"
    protocol   = "-1"
    cidr_block = "0.0.0.0/0"
  }

  tags = {
    Name = "remediation-network-acl"
  }
}

# Data sources to look up existing VPC and subnets

data "aws_subnets" "existing_subnets" {
}

variable "vpc_id" {
  description = "Target VPC ID"
  type        = string
}
