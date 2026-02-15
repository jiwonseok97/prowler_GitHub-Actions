# Attach an IAM instance profile to the EC2 instance
data "aws_iam_instance_profile" "remediation_instance_profile" {
  name = "remediation-instance-profile"
}

resource "aws_instance" "remediation_ec2_instance" {
  ami                  = var.ami_id
  instance_type        = "t2.micro"
  iam_instance_profile = var.iam_instance_profile_name

  vpc_security_group_ids = tolist(data.aws_security_groups.default.ids)
  subnet_id              = tolist(data.aws_subnets.default.ids)[0]

  tags = {
    Name = "Remediated EC2 Instance"
  }
}

# Use an existing IAM role with the required permissions
data "aws_iam_role" "existing_role" {
  name = var.iam_role_name
}

# Use an existing Amazon Linux AMI

# Use the default VPC and security groups
data "aws_security_groups" "default" {
}


data "aws_subnets" "default" {
}

# Use input variables for IAM role and instance profile names
variable "iam_role_name" {
  description = "Name of the IAM role to use for the EC2 instance"
  type        = string
}

variable "iam_instance_profile_name" {
  description = "Name of the IAM instance profile to create"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for new or managed instances"
  type        = string
  default     = ""
}

variable "vpc_id" {
  description = "Target VPC ID"
  type        = string
}
