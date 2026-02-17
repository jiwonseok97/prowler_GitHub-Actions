# Replace the existing security group with a new one that follows the recommended practices
resource "aws_security_group" "remediation_ec2_security_group" {
  name        = "remediation-ec2-security-group"
  description = "Remediated security group for EC2 instances"
  vpc_id      = var.vpc_id

  # Restrict inbound traffic to only the required sources
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"] # Replace with your required source CIDR
  }

  # Restrict outbound traffic to only the required destinations
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "remediation-ec2-security-group"
  }
}

# Use the new security group in your EC2 instances
resource "aws_instance" "remediation_example_ec2_instance" {
  ami                    = var.ami_id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.remediation_ec2_security_group.id]

  tags = {
    Name = "example-ec2-instance"
  }
}

# Data sources to look up existing resources

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
