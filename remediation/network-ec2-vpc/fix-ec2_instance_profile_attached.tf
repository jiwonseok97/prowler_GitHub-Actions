# Attach an IAM instance profile to the EC2 instance
data "aws_iam_instance_profile" "remediation_instance_profile" {
  name = "remediation-instance-profile"
}

resource "aws_instance" "remediation_instance" {
  ami                  = var.ami_id
  instance_type        = "t2.micro"
  iam_instance_profile = var.iam_instance_profile_name

  vpc_security_group_ids = tolist(data.aws_security_groups.instance_security_groups.ids)
  subnet_id              = data.aws_subnets.private_subnets.ids[0]

  tags = {
    Name = "Remediated Instance"
  }
}


data "aws_security_groups" "instance_security_groups" {
  filter {
    name = "vpc-id"
    values = [var.vpc_id]
  }
}

data "aws_subnets" "private_subnets" {
  filter {
    name = "vpc-id"
    values = [var.vpc_id]
  }

  filter {
    name = "tag-Tier"
    values = ["private"]
  }
}


variable "iam_role_name" {
  description = "Name of the IAM role to attach to the instance profile"
  type        = string
  default     = ""
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

variable "iam_instance_profile_name" {
  description = "Existing IAM instance profile name"
  type        = string
  default     = ""
}
