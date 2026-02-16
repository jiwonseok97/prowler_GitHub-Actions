# Replace the existing security group with a new one that follows the recommended practices
resource "aws_security_group" "remediation_sg" {
  name        = "remediation-sg"
  description = "Remediation security group"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"] # Restrict SSH access to a specific VPC CIDR
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # Allow all outbound traffic
  }

  tags = {
    Name = "remediation-sg"
  }
}

# Attach the new security group to the existing resource
resource "aws_network_interface_sg_attachment" "remediation_sg_attachment" {
  security_group_id    = aws_security_group.remediation_sg.id
  network_interface_id = "sg-0a48adc1c033afb1f" # Use the existing security group ID
}

# Data source to look up the default VPC

variable "vpc_id" {
  description = "Target VPC ID"
  type        = string
}
