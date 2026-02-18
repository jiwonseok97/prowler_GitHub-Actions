# Modify the existing Network ACL to restrict RDP access from the internet
resource "aws_network_acl" "remediation_acl" {
  vpc_id = var.vpc_id
  subnet_ids = data.aws_subnets.current.ids

  ingress {
    from_port  = 3389
    to_port    = 3389
    protocol   = "tcp"
    rule_no    = 100
    action     = "deny"
    cidr_block = "0.0.0.0/0"
  }

  egress {
    from_port  = 0
    to_port    = 0
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
  }

  tags = {
    Name = "remediation_acl"
  }
}

# Use a bastion host or AWS Session Manager for secure RDP access
resource "aws_instance" "remediation_bastion" {
  ami           = var.ami_id
  instance_type = "t2.micro"
  subnet_id     = tolist(data.aws_subnets.public.ids)[0]

  vpc_security_group_ids = [
    aws_security_group.remediation_bastion_sg.id
  ]

  tags = {
    Name = "remediation_bastion"
  }
}

resource "aws_security_group" "remediation_bastion_sg" {
  name = "remediation_bastion_sg"

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

# Data sources to look up existing resources

data "aws_subnets" "current" {
}

data "aws_subnets" "public" {
  filter {
    name = "tag-Tier"
    values = ["public"]
  }
}

variable "ami_id" {
  description = "AMI ID for new or managed instances"
  type        = string
  default     = ""
}

variable "vpc_id" {
  description = "Target VPC ID"
  type        = string
  default     = ""
}
