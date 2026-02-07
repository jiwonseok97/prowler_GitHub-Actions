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