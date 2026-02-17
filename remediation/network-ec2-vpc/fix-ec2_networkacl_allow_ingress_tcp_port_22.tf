# Modify the existing Network ACL to restrict SSH access from the internet
resource "aws_network_acl" "remediation_network_acl" {
  vpc_id = var.vpc_id
  subnet_ids = data.aws_subnets.current.ids

  ingress {
    from_port  = 22
    to_port    = 22
    rule_no    = 100
    protocol   = "tcp"
    action     = "deny"
    cidr_block = "0.0.0.0/0"
  }

  egress {
    from_port  = 0
    to_port    = 0
    rule_no    = 100
    protocol   = "-1"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
  }

  tags = {
    Name = "remediation-network-acl"
  }
}

# Look up the existing VPC and subnets

data "aws_subnets" "current" {
}

variable "vpc_id" {
  description = "Target VPC ID"
  type        = string
  default     = ""
}
