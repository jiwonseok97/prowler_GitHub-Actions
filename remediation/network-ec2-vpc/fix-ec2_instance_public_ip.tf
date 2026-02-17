#
# Modify the existing EC2 instance to remove the public IP address
#
resource "aws_instance" "remediation_ec2_instance" {
  ami           = var.ami_id
  instance_type = "t2.micro"
  subnet_id     = data.aws_subnets.private.ids[0]

  vpc_security_group_ids = tolist(data.aws_security_groups.allowed.ids)

  associate_public_ip_address = false

  tags = {
    Name = "remediation-ec2-instance"
  }
}

#
# Data sources to look up existing resources
#

data "aws_subnets" "private" {
  filter {
    name = "vpc-id"
    values = [var.vpc_id]
  }

  tags = {
    Tier = "private"
  }
}

data "aws_security_groups" "allowed" {

  tags = {
    Name = "allowed-security-group"
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
