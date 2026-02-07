# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Reference the existing security group
data "aws_security_group" "insecure_sg" {
  id = "sg-04e3503c576b68504"
}

# Create a new security group with the recommended configuration
resource "aws_security_group" "secure_sg" {
  name        = "secure-sg"
  description = "Secure security group"
  vpc_id      = data.aws_security_group.insecure_sg.vpc_id

  # Restrict inbound traffic to required sources
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

  # Restrict egress traffic to required destinations
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


This Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. References the existing insecure security group using the `data` source.
3. Creates a new security group with the recommended configuration:
   - Restricts inbound traffic to only allow SSH (port 22) from the `10.0.0.0/16` CIDR block and HTTP (port 80) from any source.
   - Restricts egress traffic to allow all outbound traffic.
   - Applies a tag to the new security group for identification.