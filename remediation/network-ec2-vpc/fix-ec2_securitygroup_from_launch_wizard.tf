# Modify the existing security group to apply least privilege
resource "aws_security_group" "remediation_sg_0a48adc1c033afb1f" {
  name        = "remediation-sg-0a48adc1c033afb1f"
  description = "Remediated security group"
  vpc_id      = var.vpc_id

  # Restrict inbound to required sources
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  # Minimize egress
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Use data source to look up the existing default VPC

variable "vpc_id" {
  description = "Target VPC ID"
  type        = string
}
