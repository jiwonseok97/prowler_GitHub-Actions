# Update the EC2 instance to use a newer AMI and apply the latest patches
resource "aws_instance" "remediation_ec2_instance" {
  ami                    = var.ami_id
  instance_type          = "t2.micro"
  subnet_id              = tolist(data.aws_subnets.default.ids)[0]
  vpc_security_group_ids = tolist(data.aws_security_groups.default.ids)

  iam_instance_profile = var.iam_instance_profile_name

  tags = {
    Name = "remediation-ec2-instance"
  }
}

# Use the latest Amazon Linux 2 AMI

# Use the default VPC and security groups
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


# Use the provided IAM instance profile
variable "iam_instance_profile_name" {
  type        = string
  description = "Name of the IAM instance profile to use"
  default     = ""
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
