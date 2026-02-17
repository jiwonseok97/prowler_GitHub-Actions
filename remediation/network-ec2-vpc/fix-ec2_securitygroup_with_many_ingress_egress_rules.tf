# Modify the existing security group to reduce the number of rules
resource "aws_security_group" "remediation_sg" {
  name        = "remediation-sg-0a48adc1c033afb1f"
  description = "Remediated security group"
  vpc_id      = var.vpc_id

  # Keep only the required inbound rules
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Keep only the required outbound rules
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Use a data source to look up the existing security group

variable "vpc_id" {
  description = "Target VPC ID"
  type        = string
}
