# Modify the existing Network ACL to restrict RDP access from the internet
resource "aws_network_acl" "remediation_acl_0572e1ab82993bb20" {
  vpc_id     = var.vpc_id
  subnet_ids = data.aws_subnets.existing_subnets.ids

  ingress {
    from_port  = 3389
    to_port    = 3389
    rule_no    = 100
    action     = "deny"
    cidr_block = "0.0.0.0/0"
    protocol   = "tcp"
  }

  tags = {
    Name = "remediation_acl_0572e1ab82993bb20"
  }
}



data "aws_subnets" "existing_subnets" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
}

variable "vpc_id" {
  description = "Target VPC ID"
  type        = string
}
