# Create a new VPC in a different region (e.g., us-west-2)
resource "aws_vpc" "remediation_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "Remediation VPC"
  }
}

# Create subnets in the new VPC
resource "aws_subnet" "remediation_subnet_1" {
  vpc_id     = aws_vpc.remediation_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-west-2a"
}

resource "aws_subnet" "remediation_subnet_2" {
  vpc_id     = aws_vpc.remediation_vpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-west-2b"
}

# Create an internet gateway for the new VPC
resource "aws_internet_gateway" "remediation_igw" {
  vpc_id = aws_vpc.remediation_vpc.id
}

# Create a route table and associate it with the subnets
resource "aws_route_table" "remediation_rt" {
  vpc_id = aws_vpc.remediation_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.remediation_igw.id
  }
}

resource "aws_route_table_association" "remediation_rt_assoc_1" {
  subnet_id      = aws_subnet.remediation_subnet_1.id
  route_table_id = aws_route_table.remediation_rt.id
}

resource "aws_route_table_association" "remediation_rt_assoc_2" {
  subnet_id      = aws_subnet.remediation_subnet_2.id
  route_table_id = aws_route_table.remediation_rt.id
}