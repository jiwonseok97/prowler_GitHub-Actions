resource "aws_network_acl" "remediation_acl" {
  vpc_id = var.vpc_id
  subnet_ids = data.aws_subnets.current.ids

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
    Name = "remediation-acl-${var.account_id}"
  }
}

data "aws_subnets" "current" {
}

variable "vpc_id" {
  description = "Target VPC ID"
  type        = string
  default     = ""
}

variable "account_id" {
  description = "AWS Account ID"
  type        = string
  default     = ""
}
