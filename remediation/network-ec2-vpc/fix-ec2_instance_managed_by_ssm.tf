resource "aws_ssm_activation" "remediation_ssm_activation" {
  iam_role           = var.ssm_iam_role
  name               = "remediation-ssm-activation"
  description        = "Activate EC2 instance for AWS Systems Manager"
  registration_limit = 1
  tags = {
    Name = "remediation-ssm-activation"
  }
}



resource "aws_instance" "remediation_ec2_instance" {
  instance_type        = var.instance_type
  ami                  = var.ami_id
  iam_instance_profile = var.ssm_iam_role

  tags = {
    Name = "remediation-ec2-instance"
  }
}

variable "ssm_iam_role" {
  description = "IAM role for SSM activation"
  type        = string
  default     = ""
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = ""
}

variable "ami_id" {
  description = "AMI ID for new or managed instances"
  type        = string
  default     = ""
}
