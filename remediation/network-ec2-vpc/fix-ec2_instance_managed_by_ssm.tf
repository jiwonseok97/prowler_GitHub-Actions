#Enroll the EC2 instance as a Systems Manager managed node
resource "aws_ssm_activation" "remediation_ssm_activation" {
  iam_role           = var.ssm_iam_role
  name               = "remediation-ssm-activation"
  description        = "Activate EC2 instance for Systems Manager"
  registration_limit = 1
  tags = {
    Name = "remediation-ssm-activation"
  }
}

#Create an EC2 instance profile and attach the SSM role
data "aws_iam_instance_profile" "remediation_ssm_instance_profile" {
  name = "remediation-ssm-instance-profile"
}

#Update the existing EC2 instance to use the new SSM instance profile
resource "aws_instance" "remediation_ec2_instance" {
  instance_type        = var.instance_type
  ami                  = var.ami_id
  iam_instance_profile = data.aws_iam_instance_profile.remediation_ssm_instance_profile.name
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

variable "ssm_iam_role" {
  description = "IAM role for SSM activation"
  type        = string
  default     = ""
}
