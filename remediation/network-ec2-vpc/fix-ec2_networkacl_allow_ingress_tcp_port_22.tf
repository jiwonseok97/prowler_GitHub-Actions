resource "aws_network_acl" "remediation_network_acl" {
  vpc_id     = var.vpc_id
  subnet_ids = [var.subnet_id]

  egress {
    from_port  = 22
    to_port    = 22
    rule_no    = 100
    action     = "deny"
    cidr_block = "0.0.0.0/0"
    protocol   = "tcp"
  }

  ingress {
    from_port  = 0
    to_port    = 0
    rule_no    = 1
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    protocol   = "-1"
  }

  tags = {
    Name = "Remediation Network ACL"
  }
}



variable "subnet_id" {
  description = "Target subnet ID"
  type        = string
  default     = ""
}

variable "vpc_id" {
  description = "Target VPC ID"
  type        = string
  default     = ""
}
