#
# Attach an IAM instance profile to the EC2 instance
#
data "aws_iam_instance_profile" "remediation_instance_profile" {
  name = "remediation-instance-profile"
}

resource "aws_instance" "remediation_instance" {
  ami           = var.ami_id
  instance_type = "t2.micro"

  iam_instance_profile = var.iam_instance_profile_name

  vpc_security_group_ids = var.vpc_security_group_ids
  subnet_id              = var.subnet_id

  tags = {
    Name = "remediation-instance"
  }
}

#
# Use an existing IAM role with the required permissions
#
data "aws_iam_role" "existing_role" {
  name = var.iam_role_name
}

variable "iam_role_name" {
  description = "Name of the IAM role to use for the instance profile"
  type        = string
  default     = "my-instance-role"
}

variable "vpc_security_group_ids" {
  type    = list(string)
  default = []
}

variable "ami_id" {
  description = "AMI ID for new or managed instances"
  type        = string
  default     = ""
}

variable "subnet_id" {
  description = "Target subnet ID"
  type        = string
  default     = ""
}

variable "iam_instance_profile_name" {
  description = "Existing IAM instance profile name"
  type        = string
  default     = ""
}
