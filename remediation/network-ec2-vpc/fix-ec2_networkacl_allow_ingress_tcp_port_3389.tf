#
# Modify the existing Network ACL to restrict RDP access
#
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

  # Restrict RDP access to specific IP ranges
  ingress {
    from_port  = 3389
    to_port    = 3389
    rule_no    = 200
    action     = "deny"
    protocol   = "tcp"
    cidr_block = "0.0.0.0/0"
  }

  tags = {
    Name = "remediation_acl"
  }
}


data "aws_subnets" "current" {
}

variable "vpc_id" {
  description = "Target VPC ID"
  type        = string
  default     = ""
}
