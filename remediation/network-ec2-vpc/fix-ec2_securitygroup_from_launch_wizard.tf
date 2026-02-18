#
# Replace the existing security group with a new one created using the EC2 Launch Wizard
#
resource "aws_security_group" "remediation_ec2_launch_wizard_sg" {
  name        = "remediation-ec2-launch-wizard-sg"
  description = "Remediation security group created using the EC2 Launch Wizard"
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
    Name = "remediation-ec2-launch-wizard-sg"
  }
}

variable "vpc_id" {
  description = "Target VPC ID"
  type        = string
  default     = ""
}
