# Modify the existing EC2 instance to set the desired maximum age
resource "aws_instance" "remediation_ec2_instance" {
  ami           = var.ami_id
  instance_type = "t2.micro"

  # Set the maximum age for the instance
  tags = {
    Name   = "Remediated EC2 Instance"
    MaxAge = "30"
  }
}

# Data source to get the latest Amazon Linux AMI

variable "ami_id" {
  description = "AMI ID for new or managed instances"
  type        = string
  default     = ""
}
