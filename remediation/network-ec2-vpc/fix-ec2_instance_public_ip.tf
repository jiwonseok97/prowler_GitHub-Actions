# Modify the existing EC2 instance to remove the public IP address
resource "aws_instance" "remediation_ec2_instance" {
  ami           = var.ami_id
  instance_type = "t2.micro"
  subnet_id     = data.aws_subnets.private.ids[0]
  vpc_security_group_ids = var.security_group_ids
  associate_public_ip_address = false

  tags = {
    Name = "remediation-ec2-instance"
  }
}

# Use a data source to look up the existing AMI

# Use a data source to look up the existing private subnets
data "aws_subnets" "private" {
  filter {
    name = "vpc-id"
    values = [var.vpc_id]
  }

  filter {
    name = "tag-Tier"
    values = ["private"]
  }
}

# Use a data source to look up the existing security group

variable "ami_id" {
  description = "AMI ID for new or managed instances"
  type        = string
  default     = ""
}

variable "security_group_id" {
  description = "Target security group ID"
  type        = string
  default     = ""
}

variable "vpc_id" {
  description = "Target VPC ID"
  type        = string
}

variable "security_group_ids" {
  description = "Security group IDs for instance/network resources"
  type        = list(string)
}
