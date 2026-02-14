# Retrieve the existing VPC
data "aws_vpc" "existing_vpc" {
  id = "vpc-0565167ce4f7cc871"
}

# Retrieve the existing subnets in the VPC
data "aws_subnets" "existing_subnets" {
}

# Create new subnets in different Availability Zones
resource "aws_subnet" "remediation_subnet_1" {
  vpc_id = "vpc-0565167ce4f7cc871"
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-northeast-2a"
}

resource "aws_subnet" "remediation_subnet_2" {
  vpc_id = "vpc-0565167ce4f7cc871"
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-northeast-2c"
}

# Associate the new subnets with the existing VPC
resource "aws_route_table_association" "remediation_subnet_1_association" {
  subnet_id      = aws_subnet.remediation_subnet_1.id
  route_table_id = data.aws_vpc.existing_vpc.main_route_table_id
}

resource "aws_route_table_association" "remediation_subnet_2_association" {
  subnet_id      = aws_subnet.remediation_subnet_2.id
  route_table_id = data.aws_vpc.existing_vpc.main_route_table_id
}