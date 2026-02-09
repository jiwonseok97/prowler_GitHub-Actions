# Create a new VPC with separate public and private subnets
resource "aws_vpc" "remediation_vpc" {
  cidr_block = "10.0.0.0/16"
}

# Create a public subnet in the new VPC
resource "aws_subnet" "remediation_public_subnet" {
  vpc_id            = aws_vpc.remediation_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-northeast-2a"
  map_public_ip_on_launch = true
}

# Create a private subnet in the new VPC
resource "aws_subnet" "remediation_private_subnet" {
  vpc_id            = aws_vpc.remediation_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-northeast-2c"
  map_public_ip_on_launch = false
}

# Create an internet gateway for the new VPC
resource "aws_internet_gateway" "remediation_igw" {
  vpc_id = aws_vpc.remediation_vpc.id
}

# Create a route table for the public subnet
resource "aws_route_table" "remediation_public_rt" {
  vpc_id = aws_vpc.remediation_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.remediation_igw.id
  }
}

# Associate the public subnet with the public route table
resource "aws_route_table_association" "remediation_public_rt_association" {
  subnet_id      = aws_subnet.remediation_public_subnet.id
  route_table_id = aws_route_table.remediation_public_rt.id
}

# Create a route table for the private subnet
resource "aws_route_table" "remediation_private_rt" {
  vpc_id = aws_vpc.remediation_vpc.id
}

# Associate the private subnet with the private route table
resource "aws_route_table_association" "remediation_private_rt_association" {
  subnet_id      = aws_subnet.remediation_private_subnet.id
  route_table_id = aws_route_table.remediation_private_rt.id
}