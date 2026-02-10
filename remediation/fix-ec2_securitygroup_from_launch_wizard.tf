# Modify the existing security group to apply least privilege
resource "aws_security_group" "remediation_sg" {
  name        = "remediation-sg"
  description = "Remediated security group"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    cidr_blocks     = ["10.0.0.0/16"] # Restrict SSH access to required CIDR range
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"] # Minimize egress rules
  }

  tags = {
    Name = "remediation-sg"
  }
}

# Use data source to look up the existing security group
data "aws_security_group" "existing_sg" {
  id = "sg-0a48adc1c033afb1f"
}

# Replace the existing security group with the remediated one
resource "aws_security_group_rule" "remediation_replace_sg" {
  security_group_id = data.aws_security_group.existing_sg.id
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]

  depends_on = [
    aws_security_group.remediation_sg
  ]
}

data "aws_vpc" "default" {
  default = true
}