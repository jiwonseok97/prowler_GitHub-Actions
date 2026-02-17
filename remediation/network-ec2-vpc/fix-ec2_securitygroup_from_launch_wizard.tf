# Replace the existing security group with a new one that follows the recommended practices
resource "aws_security_group" "remediation_sg" {
  name = "remediation-sg"
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

# Use the new security group in the existing EC2 instances
data "aws_instances" "affected_instances" {
}

resource "aws_network_interface_sg_attachment" "remediation_sg_attachment" {
  count                = length(data.aws_instances.affected_instances.ids)
  security_group_id    = aws_security_group.remediation_sg.id
  network_interface_id = data.aws_instances.affected_instances.ids[count.index]
}

# Optionally, you can also update the default security group to follow the recommended practices

resource "aws_security_group_rule" "remediation_default_sg_ingress_remediation" {
  security_group_id = var.security_group_id
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["10.0.0.0/16"]
}

resource "aws_security_group_rule" "remediation_default_sg_egress_remediation" {
  security_group_id = var.security_group_id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

# Look up the existing VPC

variable "security_group_id" {
  description = "Target security group ID"
  type        = string
  default     = ""
}

variable "vpc_id" {
  description = "Target VPC ID"
  type        = string
  default     = ""
}
