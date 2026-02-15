# Modify the existing EC2 instance to use HVM virtualization
resource "aws_instance" "remediation_ec2_instance" {
  ami                    = var.ami_id
  instance_type          = "t2.micro"
  subnet_id              = tolist(data.aws_subnets.default.ids)[0]
  vpc_security_group_ids = tolist(data.aws_security_groups.default.ids)

  tags = {
    Name = "remediation-ec2-instance"
  }
}

# Look up the latest HVM-based Amazon Linux 2 AMI

# Look up the default VPC and security groups
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
}

data "aws_security_groups" "default" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
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
}
