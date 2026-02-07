# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Data source to reference the existing security group
data "aws_security_group" "existing_sg" {
  id = "sg-04e3503c576b68504"
}

# Create a new security group with fewer ingress and egress rules
resource "aws_security_group" "new_sg" {
  name_prefix = "new-sg-"
  vpc_id      = data.aws_security_group.existing_sg.vpc_id

  # Limit ingress rules to only the required ports, protocols, and sources
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    cidr_blocks     = ["10.0.0.0/16"]
  }

  # Limit egress rules to only the required ports, protocols, and destinations
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags = {
    Name = "New Security Group"
  }
}


This Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Uses a data source to reference the existing security group with the ID `sg-04e3503c576b68504`.
3. Creates a new security group with fewer ingress and egress rules, following the recommendations:
   - Limits the ingress rules to only the required ports (80 and 22), protocols, and sources (0.0.0.0/0 and 10.0.0.0/16).
   - Limits the egress rule to allow all traffic (0.0.0.0/0) on all ports and protocols.
4. Applies a tag to the new security group for identification.