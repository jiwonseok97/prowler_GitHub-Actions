# Attach an IAM instance profile to the EC2 instance
data "aws_iam_instance_profile" "remediation_instance_profile" {
  name = "remediation-instance-profile"
}

resource "aws_instance" "remediation_ec2_instance" {
  ami                  = var.ami_id
  instance_type        = "t2.micro"
  iam_instance_profile = var.iam_instance_profile_name

  vpc_security_group_ids = [
    var.security_group_id
  ]

  tags = {
    Name = "Remediated EC2 Instance"
  }
}

# Use an existing IAM role with the required permissions
data "aws_iam_role" "remediation_role" {
  name = var.iam_role_name
}

# Use an existing Amazon Linux 2 AMI

# Use the default VPC security group


variable "iam_role_name" {
  description = "Name of the IAM role to attach to the EC2 instance"
  type        = string
  default     = ""
}

variable "ami_id" {
  description = "AMI ID for new or managed instances"
  type        = string
  default     = ""
}

variable "security_group_id" {
  description = "Target security group ID"
  type        = string
  default     = ""
}

variable "iam_instance_profile_name" {
  description = "Existing IAM instance profile name"
  type        = string
  default     = ""
}
