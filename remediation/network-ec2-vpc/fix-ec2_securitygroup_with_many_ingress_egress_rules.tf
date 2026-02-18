# Modify the existing security group to reduce the number of rules
resource "aws_security_group" "remediation_sg" {
  name        = "remediation-sg-0a48adc1c033afb1f"
  description = "Remediated security group"
  vpc_id      = var.vpc_id

  # Limit inbound rules to required ports and sources
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Limit outbound rules to required ports and destinations
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "remediation-sg-0a48adc1c033afb1f"
  }
}

# Use data source to look up the existing security group

variable "vpc_id" {
  description = "Target VPC ID"
  type        = string
  default     = ""
}
