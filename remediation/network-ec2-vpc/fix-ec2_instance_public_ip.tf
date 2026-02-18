# Modify the existing EC2 instance to remove the public IP address
resource "aws_instance" "remediation_ec2_instance" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = data.aws_subnets.private_subnets.ids[0]
  vpc_security_group_ids = var.security_group_ids
  # Use an existing launch template or AMI
  launch_template {
    name = var.launch_template_name
  }

  # Assign an IAM instance profile if required
  iam_instance_profile = var.iam_instance_profile_name

  # Ensure the instance is in a private subnet and does not have a public IP
  associate_public_ip_address = false
}

# Data sources to look up existing resources
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


data "aws_launch_template" "existing_template" {
  name = "existing-launch-template"
}


# Input variables for IAM instance profile and other resources
variable "iam_instance_profile_name" {
  type        = string
  description = "Name of the IAM instance profile to assign to the EC2 instance"
  default     = ""
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

variable "security_group_id" {
  description = "Target security group ID"
  type        = string
  default     = ""
}

variable "vpc_id" {
  description = "Target VPC ID"
  type        = string
  default     = ""
}

variable "security_group_ids" {
  description = "Security group IDs for instance/network resources"
  type        = list(string)
  default     = []
}
