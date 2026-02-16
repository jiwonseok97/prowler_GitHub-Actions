#
# Enroll the EC2 instance as an AWS Systems Manager managed node
#
resource "aws_ssm_activation" "remediation_ssm_activation" {
  name               = "remediation-ssm-activation"
  description        = "Activate instance for AWS Systems Manager"
  iam_role           = "AmazonEC2RoleforSSM"
  registration_limit = 1
  tags = {
    Name = "remediation-ssm-activation"
  }
}

#
# Attach the AWS Systems Manager managed instance core policy to the instance
#

#
# Update the EC2 instance to use the SSM-enabled IAM role
#
resource "aws_instance" "remediation_ec2_instance" {
  ami                  = var.ami_id
  instance_type        = "t2.micro"
  iam_instance_profile = "AmazonEC2RoleforSSM"

  vpc_security_group_ids = var.vpc_security_group_ids
  subnet_id              = var.subnet_id

  tags = {
    Name = "remediation-ec2-instance"
  }
}

#
# Data sources to look up the existing EC2 instance and Amazon Linux 2 AMI
#

variable "vpc_security_group_ids" {
  type = list(string)
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
