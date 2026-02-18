# Modify the existing Network ACL to restrict RDP access from the internet
resource "aws_network_acl" "remediation_acl" {
  vpc_id     = var.vpc_id
  subnet_ids = data.aws_subnets.current.ids

  # Allow all outbound traffic
  egress {
    from_port  = 0
    to_port    = 0
    rule_no    = 100
    protocol   = "-1"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
  }

  # Deny inbound RDP access from the internet
  ingress {
    from_port  = 3389
    to_port    = 3389
    rule_no    = 100
    protocol   = "tcp"
    action     = "deny"
    cidr_block = "0.0.0.0/0"
  }

  # Allow all other inbound traffic
  ingress {
    from_port  = 0
    to_port    = 0
    rule_no    = 200
    protocol   = "-1"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
  }

  tags = {
    Name = "remediation_acl"
  }
}

# Associate the modified Network ACL with the existing subnets
resource "aws_network_acl_association" "remediation_acl_association" {
  count          = length(data.aws_subnets.current.ids)
  network_acl_id = aws_network_acl.remediation_acl.id
  subnet_id      = data.aws_subnets.current.ids[count.index]
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
