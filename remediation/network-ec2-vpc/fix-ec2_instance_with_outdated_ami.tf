variable "subnet_ids" {
  description = "List of subnet IDs to use for the EC2 instance"
  type        = list(string)
}

variable "security_group_ids" {
  description = "List of security group IDs to use for the EC2 instance"
  type        = list(string)
}

resource "aws_instance" "remediation_ec2_instance" {
  ami                    = var.ami_id
  instance_type          = "t2.micro"
  subnet_id              = var.subnet_ids[0]
  vpc_security_group_ids = var.security_group_ids

  tags = {
    Name = "Remediated EC2 Instance"
  }
}

variable "ami_id" {
  description = "AMI ID for new or managed instances"
  type        = string
  default     = ""
}
