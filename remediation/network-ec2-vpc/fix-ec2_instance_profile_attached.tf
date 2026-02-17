# Attach an IAM instance profile to the EC2 instance
data "aws_iam_instance_profile" "remediation_instance_profile" {
  name = "remediation-instance-profile"
}

resource "aws_instance" "remediation_instance" {
  ami                  = var.ami_id
  instance_type        = var.instance_type
  iam_instance_profile = var.iam_instance_profile_name
}

data "aws_iam_role" "existing_role" {
  name = "existing-role-name"
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

variable "iam_instance_profile_name" {
  description = "Existing IAM instance profile name"
  type        = string
  default     = ""
}
