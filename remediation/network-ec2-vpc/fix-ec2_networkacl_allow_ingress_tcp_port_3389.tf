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

  # Allow all other traffic
  ingress {
    from_port  = 0
    to_port    = 0
    rule_no    = 200
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
}

# Use a data source to look up the existing VPC

# Use a data source to look up the existing subnets
data "aws_subnets" "current" {
}

variable "vpc_id" {
  description = "Target VPC ID"
  type        = string
}
