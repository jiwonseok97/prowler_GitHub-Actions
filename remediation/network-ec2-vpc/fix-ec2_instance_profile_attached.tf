resource "aws_instance" "remediation_ec2_instance" {
  ami                  = var.ami_id
  instance_type        = "t2.micro"
  iam_instance_profile = var.iam_instance_profile_name

  vpc_security_group_ids = [
    var.security_group_id
  ]

  tags = {
    Name = "Remediated Instance"
  }
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

variable "vpc_id" {
  description = "VPC ID for the default security group"
  type        = string
  default     = ""
}

variable "iam_role_name" {
  default = "remediation-role"
}

variable "iam_policy_arn" {
  default = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
