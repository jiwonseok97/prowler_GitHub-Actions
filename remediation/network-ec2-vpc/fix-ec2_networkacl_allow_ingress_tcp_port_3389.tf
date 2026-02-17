#
# Modify the existing Network ACL to restrict RDP access
#
resource "aws_network_acl" "remediation_acl" {
  vpc_id     = var.vpc_id
  subnet_ids = data.aws_subnets.current.ids

  ingress {
    from_port  = 3389
    to_port    = 3389
    protocol   = "tcp"
    rule_no    = 100
    action     = "deny"
    cidr_block = "0.0.0.0/0"
  }

  tags = {
    Name = "Remediated Network ACL"
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
  default     = ""
}
