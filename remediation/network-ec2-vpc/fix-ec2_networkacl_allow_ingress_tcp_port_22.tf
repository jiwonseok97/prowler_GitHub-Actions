#
# Modify the existing Network ACL to restrict SSH access to trusted sources
#
resource "aws_network_acl" "remediation_network_acl" {
  vpc_id = var.vpc_id
  subnet_ids = data.aws_subnets.current.ids

  ingress {
    from_port  = 22
    to_port    = 22
    rule_no    = 100
    protocol   = "tcp"
    cidr_block = "10.0.0.0/8" # Restrict SSH access to trusted VPC CIDR
    action     = "allow"
  }

  egress {
    from_port  = 0
    to_port    = 0
    rule_no    = 100
    protocol   = "-1"
    cidr_block = "0.0.0.0/0"
    action     = "allow"
  }

  tags = {
    Name = "remediation-network-acl"
  }
}


data "aws_subnets" "current" {
}

variable "vpc_id" {
  description = "Target VPC ID"
  type        = string
  default     = ""
}
