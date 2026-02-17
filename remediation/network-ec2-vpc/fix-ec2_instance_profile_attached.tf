data "aws_iam_instance_profile" "remediation_instance_profile" {
  name = var.iam_instance_profile_name
}

resource "aws_instance" "remediation_ec2_instance" {
  ami                  = var.ami_id
  instance_type        = "t2.micro"
  iam_instance_profile = data.aws_iam_instance_profile.remediation_instance_profile.name

  vpc_security_group_ids = data.aws_security_groups.default.ids
  subnet_id              = data.aws_subnets.default.ids[0]

  tags = {
    Name = "Remediated EC2 Instance"
  }
}

data "aws_security_groups" "default" {
  filter {
    name   = "tag-Name"
    values = ["default"]
  }
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
}

variable "iam_role_name" {
  description = "Name of the IAM role to attach to the EC2 instance"
  type        = string
  default     = "remediation-role"
}

variable "iam_policy_arn" {
  description = "ARN of the IAM policy to attach to the role"
  type        = string
  default     = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

variable "ami_id" {
  description = "AMI ID for new or managed instances"
  type        = string
  default     = ""
}

variable "vpc_id" {
  description = "Target VPC ID"
  type        = string
  default     = ""
}

variable "iam_instance_profile_name" {
  description = "Existing IAM instance profile name"
  type        = string
  default     = ""
}
