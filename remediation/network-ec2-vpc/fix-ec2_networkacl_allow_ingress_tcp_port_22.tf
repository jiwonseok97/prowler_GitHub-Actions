# Modify the existing Network ACL to restrict SSH access from the internet
resource "aws_network_acl" "remediation_network_acl" {
  vpc_id     = var.vpc_id
  subnet_ids = data.aws_subnets.current.ids

  ingress {
    from_port  = 22
    to_port    = 22
    protocol   = "tcp"
    rule_no    = 100
    action     = "deny"
    cidr_block = "0.0.0.0/0"
  }

  egress {
    from_port  = 0
    to_port    = 0
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
  }

  tags = {
    Name = "remediation-network-acl"
  }
}

# Look up the existing VPC and subnets

data "aws_subnets" "current" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
}

variable "vpc_id" {
  description = "Target VPC ID"
  type        = string
}
