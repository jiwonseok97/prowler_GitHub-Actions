# Modify the existing Network ACL to restrict RDP access from the internet
resource "aws_network_acl" "remediation_network_acl" {
  vpc_id = var.vpc_id
  subnet_ids = data.aws_subnets.current.ids

  # Allow all outbound traffic
  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  # Deny inbound RDP access from the internet
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "deny"
    cidr_block = "0.0.0.0/0"
    from_port  = 3389
    to_port    = 3389
  }

  # Allow all other inbound traffic
  ingress {
    protocol   = "-1"
    rule_no    = 200
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name = "remediation_network_acl"
  }
}

# Lookup the existing VPC and subnets

data "aws_subnets" "current" {
}

variable "vpc_id" {
  description = "Target VPC ID"
  type        = string
  default     = ""
}
