# Modify the existing EC2 instance to remove the public IP address
resource "aws_instance" "remediation_ec2_instance" {
  ami           = var.ami_id
  instance_type = "t2.micro"
  subnet_id     = data.aws_subnets.private.ids[0]

  vpc_security_group_ids = [
    var.security_group_id,
  ]

  associate_public_ip_address = false

  iam_instance_profile = data.aws_iam_instance_profile.existing_profile.name

  tags = {
    Name = "remediation-ec2-instance"
  }
}

# Use a data source to look up the existing AMI

# Use a data source to look up the existing private subnets
data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }

  filter {
    name   = "tag-Tier"
    values = ["private"]
  }
}

# Use a data source to look up the existing security group

# Use a data source to look up the existing IAM instance profile
data "aws_iam_instance_profile" "existing_profile" {
  name = "existing-instance-profile"
}

# Use a data source to look up the existing VPC

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
  default     = ""
}
