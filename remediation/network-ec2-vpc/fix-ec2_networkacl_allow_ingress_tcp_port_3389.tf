resource "aws_network_acl" "remediation_acl" {
  vpc_id     = var.vpc_id
  subnet_ids = data.aws_subnets.current.ids

  ingress {
    from_port  = 3389
    to_port    = 3389
    protocol   = "tcp"
    action     = "deny"
    cidr_block = "0.0.0.0/0"
    rule_no    = var.ingress_rule_no
  }

  tags = {
    Name = "Remediated Network ACL"
  }
}

resource "aws_instance" "remediation_bastion" {
  ami           = var.ami_id
  instance_type = "t2.micro"
  subnet_id     = data.aws_subnets.current.ids[0]

  vpc_security_group_ids = [
    aws_security_group.remediation_bastion_sg.id
  ]

  tags = {
    Name = "Remediation Bastion Host"
  }
}

resource "aws_security_group" "remediation_bastion_sg" {
  name   = "Remediation-Bastion-SG"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_subnets" "current" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
}

variable "ami_id" {
  description = "AMI ID for new or managed instances"
  type        = string
}

variable "vpc_id" {
  description = "Target VPC ID"
  type        = string
}

variable "ingress_rule_no" {
  description = "Ingress rule number for Network ACL"
  type        = number
}
