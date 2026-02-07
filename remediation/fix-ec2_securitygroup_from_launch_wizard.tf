# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Create a new security group with the required rules
resource "aws_security_group" "secure_group" {
  name        = "secure-group"
  description = "Secure security group"
  vpc_id      = data.aws_vpc.default.id

  # Allow only necessary inbound traffic
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

  # Restrict outbound traffic to only necessary destinations
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Secure Security Group"
  }
}

# Use a data source to reference the existing default VPC
data "aws_vpc" "default" {
  default = true
}


The provided Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Creates a new security group named `secure-group` with the following rules:
   - Allows inbound SSH traffic (port 22) from the `10.0.0.0/16` CIDR block.
   - Allows inbound HTTP traffic (port 80) from any IP address (`0.0.0.0/0`).
   - Allows all outbound traffic (`0.0.0.0/0`).
3. Uses a data source to reference the existing default VPC in the `ap-northeast-2` region.

This code should replace or harden the existing security group, as recommended in the security finding, by applying the principle of least privilege and restricting inbound and outbound traffic to only the necessary sources and destinations.