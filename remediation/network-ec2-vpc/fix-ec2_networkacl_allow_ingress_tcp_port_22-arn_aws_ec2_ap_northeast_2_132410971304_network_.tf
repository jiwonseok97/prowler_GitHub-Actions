resource "aws_network_acl" "remediation_network_acl" {
  vpc_id     = var.vpc_id
  subnet_ids = data.aws_subnets.current.ids

  egress {
    from_port  = 22
    to_port    = 22
    rule_no    = 100
    protocol   = "tcp"
    cidr_block = "0.0.0.0/0"
    action     = "deny"
  }

  egress {
    from_port  = 0
    to_port    = 0
    rule_no    = 200
    protocol   = "-1"
    cidr_block = "0.0.0.0/0"
    action     = "allow"
  }

  ingress {
    from_port  = 0
    to_port    = 0
    rule_no    = 100
    protocol   = "-1"
    cidr_block = "0.0.0.0/0"
    action     = "allow"
  }
}

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
