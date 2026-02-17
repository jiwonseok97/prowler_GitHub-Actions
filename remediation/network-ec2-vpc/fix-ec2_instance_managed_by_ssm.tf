#
# Enroll the EC2 instance as an AWS Systems Manager managed node
#
resource "aws_ssm_activation" "remediation_ssm_activation" {
  iam_role           = var.ssm_iam_role
  name               = "remediation-ssm-activation"
  description        = "Activate EC2 instance for AWS Systems Manager"
  registration_limit = 1
  tags = {
    Name = "remediation-ssm-activation"
  }
}

#
# Attach the AWS-managed SSM policy to the instance
#

#
# Ensure the EC2 instance is enrolled in AWS Systems Manager
#
resource "aws_instance" "remediation_ec2_instance" {
  instance_type          = var.instance_type
  ami                    = var.ami_id
  subnet_id              = data.aws_subnets.default.ids[0]
  vpc_security_group_ids = data.aws_security_groups.default.ids

  iam_instance_profile = aws_ssm_activation.remediation_ssm_activation.name

  tags = {
    Name = "remediation-ec2-instance"
  }
}

#
# Update the existing EC2 instance to be managed by AWS Systems Manager
#

resource "aws_instance" "remediation_ec2_instance_update" {
  instance_type          = var.instance_type
  ami                    = var.ami_id
  subnet_id              = var.subnet_id
  vpc_security_group_ids = var.vpc_security_group_ids

  iam_instance_profile = aws_ssm_activation.remediation_ssm_activation.name

  tags = {
    Name = "remediation-ec2-instance"
  }
}

#
# Retrieve the default VPC and security groups
#
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
}

data "aws_security_groups" "default" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
}

variable "ami_id" {
  description = "AMI ID for new or managed instances"
  type        = string
  default     = ""
}

variable "ssm_iam_role" {
  description = "IAM role for SSM activation"
  type        = string
  default     = ""
}

variable "vpc_id" {
  description = "Target VPC ID"
  type        = string
  default     = ""
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = ""
}

variable "instance_id" {
  description = "instance_id"
  type        = string
  default     = ""
}

variable "subnet_id" {
  description = "Target subnet ID"
  type        = string
  default     = ""
}

variable "vpc_security_group_ids" {
  type    = list(string)
  default = []
}
