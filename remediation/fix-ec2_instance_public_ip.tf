# Modify the existing EC2 instance to remove the public IP address
resource "aws_instance" "remediation_ec2_instance" {
  ami = var.ami_id
  instance_type = var.instance_type
  subnet_id   = data.aws_subnets.private.ids[0]
  vpc_security_group_ids = tolist(data.aws_security_groups.allowed.ids)
  
  # Use an existing launch template or AMI
  launch_template {
    name = var.launch_template_name
  }
  
  # Ensure the instance has no public IP
  associate_public_ip_address = false
}

# Use a private subnet for the instance
data "aws_subnets" "private" {
  filter {
    name = "vpc-id"
    values = [data.aws_vpc.current.id]
  }
  
  filter {
    name = "tag-Tier"
    values = ["private"]
  }
}

# Reference the existing security groups to apply
data "aws_security_groups" "allowed" {
  filter {
    name = "group-name"
    values = ["allowed-sg"]
  }
}

# Use an existing launch template
data "aws_launch_template" "existing" {
  name = "my-launch-template"
}

# Use the current VPC
data "aws_vpc" "current" {
  default = true
}

# Use the current AWS provider configuration

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