#
# Remediate the EC2 instance that is not older than the configured maximum age or is not running
#

resource "aws_instance" "remediation_ec2_instance" {
  ami                    = var.ami_id
  instance_type          = "t2.micro"
  subnet_id              = tolist(data.aws_subnets.default.ids)[0]
  vpc_security_group_ids = tolist(data.aws_security_groups.default.ids)

  iam_instance_profile = var.iam_instance_profile_name

  tags = {
    Name = "Remediated EC2 Instance"
  }
}


data "aws_subnets" "default" {
  filter {
    name   = "default-for-az"
    values = ["true"]
  }
}

data "aws_security_groups" "default" {
  filter {
    name   = "group-name"
    values = ["default"]
  }
}

variable "iam_instance_profile_name" {
  description = "Name of the IAM instance profile to use for the EC2 instance"
  type        = string
  default     = ""
}

variable "ami_id" {
  description = "AMI ID for new or managed instances"
  type        = string
  default     = ""
}
