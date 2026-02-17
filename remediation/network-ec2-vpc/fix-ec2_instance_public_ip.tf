#
# Modify the existing EC2 instance to remove the public IP address
#
resource "aws_instance" "remediation_ec2_instance" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = data.aws_subnets.private.ids[0]

  associate_public_ip_address = false

  # Use an existing launch template or AMI
  launch_template {
    name = var.launch_template_name
  }

  # Use existing IAM instance profile
  iam_instance_profile = data.aws_iam_instance_profile.existing.name

  # Use existing security groups
  vpc_security_group_ids = tolist(data.aws_security_groups.existing.ids)
}

#
# Data sources to look up existing resources
#
data "aws_subnets" "private" {
  filter {
    name = "vpc-id"
    values = [var.vpc_id]
  }

  filter {
    name = "tag-Tier"
    values = ["private"]
  }
}

data "aws_launch_template" "existing" {
  name = "my-launch-template"
}

data "aws_iam_instance_profile" "existing" {
  name = "my-instance-profile"
}

data "aws_security_groups" "existing" {
  tags = {
    Name = "my-security-group"
  }
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
