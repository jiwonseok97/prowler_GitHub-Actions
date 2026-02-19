#
# Remediate the security group not created using the EC2 Launch Wizard
#

resource "aws_security_group" "remediation_sg" {
  name        = "remediation-sg"
  description = "Remediation security group"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

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

variable "vpc_id" {
  description = "Target VPC ID"
  type        = string
  default     = ""
}
