# Create a new VPC with subnets in 2 different Availability Zones
resource "aws_vpc" "remediation_vpc" {
  cidr_block = "10.0.0.0/16"
}

# Create a public subnet in AZ 1
resource "aws_subnet" "remediation_public_subnet_1" {
  vpc_id            = aws_vpc.remediation_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-northeast-2a"
}

# Create a public subnet in AZ 2
resource "aws_subnet" "remediation_public_subnet_2" {
  vpc_id            = aws_vpc.remediation_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-northeast-2c"
}

# Create an internet gateway and attach it to the VPC
resource "aws_internet_gateway" "remediation_igw" {
  vpc_id = aws_vpc.remediation_vpc.id
}

# Create a route table for the public subnets and associate it with the subnets
resource "aws_route_table" "remediation_public_rt" {
  vpc_id = aws_vpc.remediation_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.remediation_igw.id
  }
}

resource "aws_route_table_association" "remediation_public_subnet_1_rt_association" {
  subnet_id      = aws_subnet.remediation_public_subnet_1.id
  route_table_id = aws_route_table.remediation_public_rt.id
}

resource "aws_route_table_association" "remediation_public_subnet_2_rt_association" {
  subnet_id      = aws_subnet.remediation_public_subnet_2.id
  route_table_id = aws_route_table.remediation_public_rt.id
}