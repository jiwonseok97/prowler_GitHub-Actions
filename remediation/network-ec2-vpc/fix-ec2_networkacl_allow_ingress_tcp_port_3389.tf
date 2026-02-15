# Modify the existing Network ACL to restrict RDP access from the internet
resource "aws_network_acl" "remediation_network_acl" {
  vpc_id     = var.vpc_id
  subnet_ids = data.aws_subnets.current.ids

  # Allow all traffic outbound
  egress {
    from_port  = 0
    to_port    = 0
    rule_no    = 100
    protocol   = "-1"
    cidr_block = "0.0.0.0/0"
    action     = "allow"
  }

  # Deny RDP access from the internet
  ingress {
    from_port  = 3389
    to_port    = 3389
    rule_no    = 100
    protocol   = "tcp"
    cidr_block = "0.0.0.0/0"
    action     = "deny"
  }

  # Allow all other traffic inbound
  ingress {
    from_port  = 0
    to_port    = 0
    rule_no    = 200
    protocol   = "-1"
    cidr_block = "0.0.0.0/0"
    action     = "allow"
  }

  tags = {
    Name = "remediation_network_acl"
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
}
