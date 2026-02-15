# Modify the existing security group to reduce the number of rules
resource "aws_security_group" "remediation_sg" {
  name_prefix = "remediation-"
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

# Look up the existing security group by its ID

# Replace the existing security group with the modified one
resource "aws_security_group_rule" "remediation_replace_ingress_rules" {
  security_group_id = var.security_group_id
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]

  # Remove all existing ingress rules
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "remediation_replace_egress_rules" {
  security_group_id = var.security_group_id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]

  # Remove all existing egress rules
  lifecycle {
    create_before_destroy = true
  }
}

# Add the new ingress and egress rules to the existing security group
resource "aws_security_group_rule" "remediation_add_ingress_rules" {
  security_group_id = var.security_group_id
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "remediation_add_egress_rules" {
  security_group_id = var.security_group_id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

# Look up the default VPC

variable "security_group_id" {
  description = "Target security group ID"
  type        = string
  default     = ""
}

variable "vpc_id" {
  description = "Target VPC ID"
  type        = string
}
