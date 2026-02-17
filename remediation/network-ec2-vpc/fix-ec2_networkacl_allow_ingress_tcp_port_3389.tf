# Modify the existing Network ACL to restrict RDP access from the internet
resource "aws_network_acl" "remediation_acl" {
  vpc_id = var.vpc_id
  subnet_ids = data.aws_subnets.current.ids

  ingress {
    from_port  = 3389
    to_port    = 3389
    rule_no    = 100
    action     = "deny"
    cidr_block = "0.0.0.0/0"
    protocol   = "tcp"
  }

  tags = {
    Name = "Remediated Network ACL"
  }
}

# Use a bastion host or AWS Session Manager for secure RDP access
resource "aws_security_group" "remediation_bastion_sg" {
  name = "Remediation-Bastion-Host-SG"

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

resource "aws_instance" "remediation_bastion_host" {
  ami           = var.ami_id
  instance_type = "t2.micro"
  subnet_id     = tolist(data.aws_subnets.current.ids)[0]

  vpc_security_group_ids = [aws_security_group.remediation_bastion_sg.id]

  tags = {
    Name = "Remediation Bastion Host"
  }
}

# Lookup existing VPC and subnets

data "aws_subnets" "current" {
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
