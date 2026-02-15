# Modify the existing EC2 instance to use an HVM/Nitro virtualization type
resource "aws_instance" "remediation_ec2_instance" {
  ami           = var.ami_id
  instance_type = "t3.micro"
  subnet_id     = data.aws_subnets.default.ids[0]

  vpc_security_group_ids = tolist(data.aws_security_groups.default.ids)

  iam_instance_profile = data.aws_iam_instance_profile.default.name

  tags = {
    Name = "remediation-ec2-instance"
  }
}

# Use a data source to find an HVM/Nitro-based AMI

# Use data sources to reference the default VPC and security groups
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


# Use a data source to reference the default IAM instance profile
data "aws_iam_instance_profile" "default" {
  name = "default"
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
