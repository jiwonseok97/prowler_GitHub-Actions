# Create a new security group to replace the one identified in the finding
resource "aws_security_group" "remediation_ec2_securitygroup_from_launch_wizard" {
  name        = "remediation-ec2-securitygroup-from-launch-wizard"
  description = "Remediation security group for finding ec2_securitygroup_from_launch_wizard"
  vpc_id      = data.aws_vpc.default.id

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
}

# Look up the default VPC in the current AWS account and region
data "aws_vpc" "default" {
  default = true
}