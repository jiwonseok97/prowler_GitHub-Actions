# Modify the existing Network ACL to remove the TCP port 3389 (RDP) ingress rule
resource "aws_network_acl" "remediation_acl" {
  vpc_id = var.vpc_id
  subnet_ids = data.aws_subnets.current.ids

  # Remove the ingress rule for TCP port 3389
  ingress {
    from_port  = 0
    to_port    = 0
    rule_no    = 100
    action     = "allow"
    protocol   = "-1"
    cidr_block = "0.0.0.0/0"
  }

  # Add a new ingress rule to deny TCP port 3389 from 0.0.0.0/0
  ingress {
    from_port  = 3389
    to_port    = 3389
    rule_no    = 110
    action     = "deny"
    protocol   = "tcp"
    cidr_block = "0.0.0.0/0"
  }

  # Copy the existing egress rules
  egress {
    from_port  = 0
    to_port    = 0
    rule_no    = 100
    action     = "allow"
    protocol   = "-1"
    cidr_block = "0.0.0.0/0"
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
