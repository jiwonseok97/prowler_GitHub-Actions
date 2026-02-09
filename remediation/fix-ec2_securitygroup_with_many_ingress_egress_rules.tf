# Create a new security group with limited inbound and outbound rules
resource "aws_security_group" "remediation_sg" {
  name        = "remediation_sg"
  description = "Remediation security group"
  vpc_id      = "vpc-0123456789abcdef"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.remediation_web_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create a new security group for web workloads
resource "aws_security_group" "remediation_web_sg" {
  name        = "remediation_web_sg"
  description = "Remediation web security group"
  vpc_id      = "vpc-0123456789abcdef"

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
}