# Modify the existing Network ACL to restrict SSH access from the internet
resource "aws_network_acl" "remediation_network_acl" {
  vpc_id     = var.vpc_id
  subnet_ids = data.aws_subnets.current.ids

  ingress {
    from_port  = 22
    to_port    = 22
    rule_no    = 100
    protocol   = "tcp"
    cidr_block = "10.0.0.0/8"
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
  default     = ""
}
