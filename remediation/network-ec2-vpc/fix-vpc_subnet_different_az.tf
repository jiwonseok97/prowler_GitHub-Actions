# Retrieve existing VPC and subnets

data "aws_subnets" "existing" {
}

# Create new subnets in different Availability Zones
resource "aws_subnet" "remediation_1" {
  vpc_id = "vpc-0565167ce4f7cc871"
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-northeast-2a"
}

resource "aws_subnet" "remediation_2" {
  vpc_id = "vpc-0565167ce4f7cc871"
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-northeast-2b"
}

# Associate the new subnets with the existing VPC
resource "aws_route_table_association" "remediation_1" {
  subnet_id      = aws_subnet.remediation_1.id
  route_table_id = var.vpc_id
}

resource "aws_route_table_association" "remediation_2" {
  subnet_id      = aws_subnet.remediation_2.id
  route_table_id = var.vpc_id
}

variable "vpc_id" {
  description = "Target VPC ID"
  type        = string
}
