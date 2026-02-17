# Modify the existing EC2 instance to remove the public IP address
resource "aws_instance" "remediation_ec2_instance" {
  ami           = var.ami_id
  instance_type = "t2.micro"
  subnet_id     = data.aws_subnets.private.ids[0]
  vpc_security_group_ids = var.security_group_ids
  associate_public_ip_address = false

  iam_instance_profile = var.iam_instance_profile_name

  tags = {
    Name = "remediation-ec2-instance"
  }
}

# Use a data source to look up the existing Amazon Linux AMI

# Use a data source to look up the existing default VPC and private subnets
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



# Use an input variable for the IAM instance profile name
variable "iam_instance_profile_name" {
  description = "Name of the IAM instance profile to use"
  type        = string
  default     = ""
}

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

variable "security_group_ids" {
  description = "Security group IDs for instance/network resources"
  type        = list(string)
  default     = []
}
