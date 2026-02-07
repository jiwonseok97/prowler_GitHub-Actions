# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Create a new security group to replace the existing one
resource "aws_security_group" "new_security_group" {
  name        = "new-security-group"
  description = "Replaces the security group created by the EC2 Launch Wizard"
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
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "new-security-group"
  }
}

# Use a data source to reference the default VPC
data "aws_vpc" "default" {
  default = true
}