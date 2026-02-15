# Modify the existing EC2 instance to set the desired maximum age
resource "aws_instance" "remediation_ec2_instance" {
  ami           = var.ami_id
  instance_type = "t2.micro"

  # Set the maximum age for the EC2 instance in days

  vpc_security_group_ids = var.vpc_security_group_ids
  subnet_id              = var.subnet_id
  iam_instance_profile   = data.aws_iam_instance_profile.existing.name

  tags = {
    Name = "remediation-ec2-instance"
  }
}

# Use a data source to look up the existing EC2 instance

# Use a data source to look up the latest Amazon Linux AMI

# Use a data source to look up the existing IAM instance profile
data "aws_iam_instance_profile" "existing" {
  name = var.instance_id
}

variable "vpc_security_group_ids" {
  type = list(string)
}

variable "ami_id" {
  description = "AMI ID for new or managed instances"
  type        = string
  default     = ""
}

variable "instance_id" {
  description = "instance_id"
  type        = string
  default     = ""
}

variable "subnet_id" {
  description = "Target subnet ID"
  type        = string
  default     = ""
}
