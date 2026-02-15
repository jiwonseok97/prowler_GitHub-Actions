variable "ami_id" {
  type        = string
  description = "The ID of the Amazon Machine Image (AMI) to use for the EC2 instance"
}

variable "subnet_ids" {
  type        = list(string)
  description = "The IDs of the subnets in which to create the EC2 instance"
}

variable "security_group_ids" {
  type        = list(string)
  description = "The IDs of the security groups to apply to the EC2 instance"
}


#
# Enroll the EC2 instance as a Systems Manager managed node
#
resource "aws_ssm_activation" "remediation_ssm_activation" {
  name               = "remediation-ssm-activation"
  description        = "Activate EC2 instance for Systems Manager"
  iam_role           = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/AmazonEC2RoleforSSM"
  registration_limit = 1
  tags = {
    Name = "remediation-ssm-activation"
  }
}

#
# Attach the Systems Manager managed instance core policy to the instance
#

#
# Ensure the EC2 instance is enrolled in Systems Manager
#
resource "aws_instance" "remediation_ec2_instance" {
  ami                    = var.ami_id
  instance_type          = "t2.micro"
  subnet_id              = var.subnet_ids[0]
  vpc_security_group_ids = var.security_group_ids

  iam_instance_profile = aws_ssm_activation.remediation_ssm_activation.iam_role

  tags = {
    Name = "remediation-ec2-instance"
  }
}
