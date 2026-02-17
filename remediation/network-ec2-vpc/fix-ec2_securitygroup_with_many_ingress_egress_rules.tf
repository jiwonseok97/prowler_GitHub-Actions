# Modify the existing security group to reduce the number of rules
resource "aws_security_group" "remediation_sg" {
  name_prefix = "remediation-"
  vpc_id      = var.vpc_id

  # Keep only the required inbound rules
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.remediation_web_tier.id]
  }

  # Keep only the required outbound rules
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

# Create a new security group for the web tier
resource "aws_security_group" "remediation_web_tier" {
  name_prefix = "web-tier-"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "web-tier-sg"
  }
}

# Look up the existing VPC

variable "vpc_id" {
  description = "Target VPC ID"
  type        = string
  default     = ""
}
