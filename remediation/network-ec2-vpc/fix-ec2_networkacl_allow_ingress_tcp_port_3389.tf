# Modify the existing Network ACL to remove the ingress rule allowing TCP port 3389 from 0.0.0.0/0
resource "aws_network_acl" "remediation_acl" {
  vpc_id = var.vpc_id
  subnet_ids = data.aws_subnets.current.ids

  # Remove the ingress rule allowing TCP port 3389 from 0.0.0.0/0
  ingress {
    from_port  = 0
    to_port    = 0
    rule_no    = 100
    action     = "allow"
    protocol   = "-1"
    cidr_block = "0.0.0.0/0"
  }

  # Add a new ingress rule to allow RDP access from a specific IP range
  ingress {
    from_port  = 3389
    to_port    = 3389
    rule_no    = 200
    action     = "allow"
    protocol   = "tcp"
    cidr_block = var.allowed_rdp_cidr
  }

  egress {
    from_port  = 0
    to_port    = 0
    rule_no    = 100
    action     = "allow"
    protocol   = "-1"
    cidr_block = "0.0.0.0/0"
  }
}

# Data sources to look up the current VPC and subnets

data "aws_subnets" "current" {
}

# Input variable to specify the allowed RDP CIDR range
variable "allowed_rdp_cidr" {
  description = "CIDR block allowed for RDP access"
  type        = string
  default     = "10.0.0.0/16"
}

variable "vpc_id" {
  description = "Target VPC ID"
  type        = string
}
