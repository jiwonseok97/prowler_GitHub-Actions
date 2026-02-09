# Remediate the VPC subnet across multiple Availability Zones
# Use data sources to reference existing VPC and subnets
data "aws_vpc" "existing_vpc" {
  id = "vpc-0565167ce4f7cc871"
}

data "aws_subnets" "existing_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.existing_vpc.id]
  }
}

# Create new subnets in different Availability Zones
resource "aws_subnet" "remediation_subnet_1" {
  vpc_id            = data.aws_vpc.existing_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-northeast-2a"
}

resource "aws_subnet" "remediation_subnet_2" {
  vpc_id            = data.aws_vpc.existing_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-northeast-2b"
}

# Associate the new subnets with the existing VPC
resource "aws_route_table_association" "remediation_subnet_1_route" {
  subnet_id      = aws_subnet.remediation_subnet_1.id
  route_table_id = data.aws_route_table.existing_route_table.id
}

resource "aws_route_table_association" "remediation_subnet_2_route" {
  subnet_id      = aws_subnet.remediation_subnet_2.id
  route_table_id = data.aws_route_table.existing_route_table.id
}

# Retrieve the existing route table for the VPC
data "aws_route_table" "existing_route_table" {
  vpc_id = data.aws_vpc.existing_vpc.id
}