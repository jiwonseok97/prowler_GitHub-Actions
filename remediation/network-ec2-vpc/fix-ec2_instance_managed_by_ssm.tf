resource "aws_ssm_activation" "remediation_ssm_activation" {
  name               = "remediation-ssm-activation"
  description        = "Activate EC2 instance for AWS Systems Manager"
  iam_role           = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/AmazonEC2RoleforSSM"
  registration_limit = 1

  tags = {
    Name = "remediation-ssm-activation"
  }
}


resource "aws_instance" "remediation_ec2_instance" {
  ami                  = var.ami_id
  instance_type        = var.instance_type
  iam_instance_profile = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:instance-profile/AmazonEC2RoleforSSM"

  tags = {
    Name = "remediation-ec2-instance"
  }
}

resource "aws_instance" "remediation_ec2_instance_update" {
  ami                  = var.ami_id
  instance_type        = var.instance_type
  iam_instance_profile = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:instance-profile/AmazonEC2RoleforSSM"

  tags = {
    Name = "remediation-ec2-instance"
  }
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
