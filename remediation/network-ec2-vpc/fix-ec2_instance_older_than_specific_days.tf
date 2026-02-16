#
# Remediate the EC2 instance that is not older than the configured maximum age or is not running
#

resource "aws_instance" "remediation_ec2_instance" {
  ami                    = var.ami_id
  instance_type          = "t2.micro"
  subnet_id              = tolist(data.aws_subnets.default.ids)[0]
  vpc_security_group_ids = tolist(data.aws_security_groups.default.ids)

  iam_instance_profile = var.iam_instance_profile_name

  tags = {
    Name = "Remediation-EC2-Instance"
  }
}


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


variable "iam_instance_profile_name" {
  type        = string
  description = "Name of the IAM instance profile to use for the EC2 instance"
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
