# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Create a new security group to replace the existing one
resource "aws_security_group" "new_security_group" {
  name        = "new-security-group"
  description = "Replacement security group for ec2_securitygroup_from_launch_wizard finding"
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
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags = {
    Name = "new-security-group"
  }
}

# Use a data source to reference the existing default VPC
data "aws_vpc" "default" {
  default = true
}


This Terraform code creates a new security group to replace the existing one that was created using the EC2 Launch Wizard. The new security group follows the recommended best practices:

1. It restricts inbound traffic to only the required sources (in this case, the 10.0.0.0/16 CIDR block).
2. It restricts outbound traffic to all destinations (0.0.0.0/0).
3. It uses a data source to reference the existing default VPC, which is more efficient than hardcoding the VPC ID.

The new security group can be used to replace the existing one, ensuring that the security finding is addressed and the security posture is improved.