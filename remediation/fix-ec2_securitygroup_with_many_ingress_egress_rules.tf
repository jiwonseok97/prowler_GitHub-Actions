# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Data source to reference the existing security group
data "aws_security_group" "existing_sg" {
  id = "sg-04e3503c576b68504"
}

# Create a new security group with fewer inbound and outbound rules
resource "aws_security_group" "new_sg" {
  name_prefix = "new-sg-"
  vpc_id      = data.aws_security_group.existing_sg.vpc_id

  # Limit inbound rules to only the required ports, protocols, and sources
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    cidr_blocks     = ["10.0.0.0/16"]
  }

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  # Limit outbound rules to only the required ports, protocols, and destinations
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


This Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Uses a data source to reference the existing security group with the ID `sg-04e3503c576b68504`.
3. Creates a new security group with fewer inbound and outbound rules, following the recommendations:
   - Limits the inbound rules to only the required ports (22 and 80) and sources (10.0.0.0/16 and 0.0.0.0/0).
   - Limits the outbound rule to allow all traffic (0.0.0.0/0).
4. Applies a name tag to the new security group.