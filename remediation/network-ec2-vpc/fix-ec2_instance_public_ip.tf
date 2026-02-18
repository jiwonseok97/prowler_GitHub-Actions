#
# Modify the existing EC2 instance to remove the public IP address
#
resource "aws_instance" "remediation_ec2_instance" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = data.aws_subnets.private_subnets.ids[0]

  associate_public_ip_address = false

  vpc_security_group_ids = tolist(data.aws_security_groups.allowed_security_groups.ids)

  # Use an existing launch template or AMI
  launch_template {
    name = var.launch_template_name
  }
}

#
# Data sources to look up existing resources
#
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

data "aws_security_groups" "allowed_security_groups" {
  filter {
    name = "group-name"
    values = ["allowed-sg-1", "allowed-sg-2"]
  }
}

data "aws_launch_template" "existing_template" {
  name = "existing-launch-template"
}

variable "ami_id" {
  description = "AMI ID for new or managed instances"
  type        = string
  default     = ""
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = ""
}

variable "launch_template_name" {
  description = "EC2 launch template name"
  type        = string
  default     = ""
}

variable "vpc_id" {
  description = "Target VPC ID"
  type        = string
  default     = ""
}
