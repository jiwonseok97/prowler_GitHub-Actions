# Modify the existing EC2 instance to comply with the security finding
resource "aws_instance" "remediation_ec2_instance" {
  ami                    = var.ami_id
  instance_type          = "t2.micro"
  subnet_id              = tolist(data.aws_subnets.default.ids)[0]
  vpc_security_group_ids = tolist(data.aws_security_groups.default.ids)

  tags = {
    Name = "Remediated EC2 Instance"
  }
}

# Use the latest Amazon Linux 2 AMI

# Use the default VPC and security groups
data "aws_subnets" "default" {
  filter {
    name = "vpc-id"
    values = [var.vpc_id]
  }
}

data "aws_security_groups" "default" {
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
