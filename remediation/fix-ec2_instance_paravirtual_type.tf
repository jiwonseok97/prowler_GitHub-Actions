# Modify the existing EC2 instance to use an HVM/Nitro virtualization type
resource "aws_instance" "remediation_ec2_instance" {
  ami           = data.aws_ami.hvm_ami.id
  instance_type = "t3.micro"
  subnet_id     = data.aws_subnets.private.ids[0]

  vpc_security_group_ids = tolist(data.aws_security_groups.existing.ids)

  iam_instance_profile = data.aws_iam_instance_profile.existing.name

  tags = {
    Name = "remediation-ec2-instance"
  }
}

data "aws_ami" "hvm_ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

data "aws_subnets" "private" {
  filter {
    name = "vpc-id"
    values = [data.aws_vpc.existing.id]
  }

  filter {
    name = "tag-Name"
    values = ["private-*"]
  }
}

data "aws_security_groups" "existing" {
}

data "aws_iam_instance_profile" "existing" {
  name = "my-instance-profile"
}

data "aws_vpc" "existing" {
  id = var.vpc_id
}

variable "vpc_id" {
  description = "Target VPC ID"
  type        = string
}