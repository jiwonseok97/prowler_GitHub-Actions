# Modify the existing Network ACL to remove the allow rule for TCP port 22 (SSH) from 0.0.0.0/0
resource "aws_network_acl" "remediation_network_acl" {
  vpc_id     = var.vpc_id
  subnet_ids = [var.subnet_id]

  # Remove the allow rule for TCP port 22 from 0.0.0.0/0
  ingress {
    from_port  = 0
    to_port    = 0
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    protocol   = "-1"
  }

  # Add a deny rule for TCP port 22 from 0.0.0.0/0
  ingress {
    from_port  = 22
    to_port    = 22
    rule_no    = 200
    action     = "deny"
    cidr_block = "0.0.0.0/0"
    protocol   = "tcp"
  }

  # Copy the existing egress rules
  egress {
    from_port  = 0
    to_port    = 0
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    protocol   = "-1"
  }
}

# Look up the existing subnet using data sources

variable "subnet_id" {
  description = "Target subnet ID"
  type        = string
  default     = ""
}

variable "vpc_id" {
  description = "Target VPC ID"
  type        = string
}
