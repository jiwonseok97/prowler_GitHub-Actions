# Create a new VPC in a different region (ap-southeast-1)
resource "aws_vpc" "remediation_vpc" {
  cidr_block = "10.0.0.0/16"
  
  tags = {
    Name = "remediation-vpc"
  }
}

# Create subnets in the new VPC
resource "aws_subnet" "remediation_public_subnet" {
  vpc_id     = aws_vpc.remediation_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-southeast-1a"

  tags = {
    Name = "remediation-public-subnet"
  }
}

resource "aws_subnet" "remediation_private_subnet" {
  vpc_id     = aws_vpc.remediation_vpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "ap-southeast-1b"

  tags = {
    Name = "remediation-private-subnet"
  }
}

# Create an internet gateway for the new VPC
resource "aws_internet_gateway" "remediation_igw" {
  vpc_id = aws_vpc.remediation_vpc.id

  tags = {
    Name = "remediation-igw"
  }
}

# Create a route table and associate it with the public subnet
resource "aws_route_table" "remediation_public_rt" {
  vpc_id = aws_vpc.remediation_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.remediation_igw.id
  }

  tags = {
    Name = "remediation-public-rt"
  }
}

resource "aws_route_table_association" "remediation_public_subnet_rt_association" {
  subnet_id      = aws_subnet.remediation_public_subnet.id
  route_table_id = aws_route_table.remediation_public_rt.id
}

# Create a NAT gateway for the private subnet
resource "aws_eip" "remediation_nat_eip" {
  count = 1
}

resource "aws_nat_gateway" "remediation_nat_gw" {
  allocation_id = aws_eip.remediation_nat_eip[0].id
  subnet_id     = aws_subnet.remediation_public_subnet.id
}

# Create a route table and associate it with the private subnet
resource "aws_route_table" "remediation_private_rt" {
  vpc_id = aws_vpc.remediation_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    gateway_id     = aws_nat_gateway.remediation_nat_gw.id
  }

  tags = {
    Name = "remediation-private-rt"
  }
}

resource "aws_route_table_association" "remediation_private_subnet_rt_association" {
  subnet_id      = aws_subnet.remediation_private_subnet.id
  route_table_id = aws_route_table.remediation_private_rt.id
}