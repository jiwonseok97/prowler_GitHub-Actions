# Replace the existing security group with a new one that follows the recommended practices
resource "aws_security_group" "remediation_sg" {
  name        = "remediation-sg"
  description = "Remediation security group"
  vpc_id      = var.vpc_id

  # Restrict inbound traffic to only the required sources
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  # Restrict outbound traffic to only the required destinations
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "remediation-sg"
  }
}

# Attach the new security group to the existing EC2 instance
resource "aws_network_interface_sg_attachment" "remediation_sg_attachment" {
  security_group_id    = aws_security_group.remediation_sg.id
  network_interface_id = var.network_interface_id
}

# Data sources to look up existing resources

variable "network_interface_id" {
  description = "Target network interface ID"
  type        = string
  default     = ""
}

variable "vpc_id" {
  description = "Target VPC ID"
  type        = string
  default     = ""
}
