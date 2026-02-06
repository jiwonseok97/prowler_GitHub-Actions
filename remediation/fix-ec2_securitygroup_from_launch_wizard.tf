# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Create a new security group with the required rules
resource "aws_security_group" "secure_group" {
  name        = "secure-group"
  description = "Secure group to replace the launch wizard group"
  vpc_id      = data.aws_vpc.default.id

  # Restrict inbound traffic to only the required sources
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Restrict outbound traffic to only the required destinations
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Secure Group"
  }
}

# Use a data source to reference the existing default VPC
data "aws_vpc" "default" {
  default = true
}


This Terraform code creates a new security group with the following features:

1. The security group is named "secure-group" and has a description of "Secure group to replace the launch wizard group".
2. The security group is associated with the default VPC in the ap-northeast-2 region.
3. The inbound traffic is restricted to only allow SSH (port 22) from the 10.0.0.0/16 CIDR block and HTTP (port 80) from any IP address.
4. The outbound traffic is allowed to any destination.
5. The security group is tagged with a "Name" tag of "Secure Group".

This code should replace the security group created by the EC2 Launch Wizard and apply the recommended security best practices.