# Modify the existing Network ACL to remove the ingress rule allowing TCP port 3389 from 0.0.0.0/0
resource "aws_network_acl" "remediation_acl" {
  vpc_id     = data.aws_vpc.current.id
  subnet_ids = data.aws_subnets.current.ids

  ingress {
    from_port   = 0
    to_port     = 0
    rule_no    = 100
    action     = "allow"
    protocol    = "-1"
    cidr_block = "0.0.0.0/0"
  }

  egress {
    from_port   = 0
    to_port     = 0 
    rule_no    = 100
    action     = "allow"
    protocol    = "-1"
    cidr_block = "0.0.0.0/0"
  }

  tags = {
    Name = "remediation-acl-${data.aws_caller_identity.current.account_id}"
  }
}

data "aws_vpc" "current" {
  id = "vpc-0572e1ab82993bb20"
}

data "aws_subnets" "current" {
  filter {
    name = "vpc-id"
    values = [data.aws_vpc.current.id]
  }
}