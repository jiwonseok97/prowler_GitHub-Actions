# Modify the existing EC2 instance to set a new maximum age
resource "aws_instance" "remediation_ec2_instance" {
  ami           = var.ami_id
  instance_type = "t2.micro"

  # Attach the existing IAM instance profile
  iam_instance_profile = var.iam_instance_profile_name

  # Attach the existing security groups
  vpc_security_group_ids = var.vpc_security_group_ids

  # Set the maximum age for the instance
  tags = {
    Name   = "Remediated EC2 Instance"
    MaxAge = var.max_ec2_instance_age_in_days
  }
}

# Use a data source to get the latest Amazon Linux AMI

# Use a data source to get the existing EC2 instance details

# Input variables for the IAM instance profile and maximum instance age
variable "iam_instance_profile_name" {
  type        = string
  description = "Name of the IAM instance profile to attach to the EC2 instance"
}

variable "max_ec2_instance_age_in_days" {
  type        = number
  description = "Maximum age in days for the EC2 instance"
}

variable "vpc_security_group_ids" {
  type = list(string)
}

variable "ami_id" {
  description = "AMI ID for new or managed instances"
  type        = string
  default     = ""
}
