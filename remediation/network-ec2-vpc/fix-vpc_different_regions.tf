# Create a new VPC in a different region
resource "aws_vpc" "remediation_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "Remediation VPC"
  }
}

# Create subnets in the new VPC
resource "aws_subnet" "remediation_public_subnet" {
  vpc_id            = aws_vpc.remediation_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-northeast-1a"
  tags = {
    Name = "Remediation Public Subnet"
  }
}

resource "aws_subnet" "remediation_private_subnet" {
  vpc_id            = aws_vpc.remediation_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-northeast-1b"
  tags = {
    Name = "Remediation Private Subnet"
  }
}

# Create an internet gateway for the new VPC
resource "aws_internet_gateway" "remediation_igw" {
  vpc_id = aws_vpc.remediation_vpc.id
  tags = {
    Name = "Remediation Internet Gateway"
  }
}

# Create a route table for the public subnet
resource "aws_route_table" "remediation_public_rt" {
  vpc_id = aws_vpc.remediation_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.remediation_igw.id
  }
  tags = {
    Name = "Remediation Public Route Table"
  }
}

# Associate the public subnet with the public route table
resource "aws_route_table_association" "remediation_public_subnet_rt_association" {
  subnet_id      = aws_subnet.remediation_public_subnet.id
  route_table_id = aws_route_table.remediation_public_rt.id
}

# Create a NAT gateway for the private subnet
resource "aws_nat_gateway" "remediation_nat_gateway" {
  allocation_id = aws_eip.remediation_nat_eip.id
  subnet_id     = aws_subnet.remediation_public_subnet.id
  tags = {
    Name = "Remediation NAT Gateway"
  }
}

# Create an Elastic IP for the NAT gateway
resource "aws_eip" "remediation_nat_eip" {
  tags = {
    Name = "Remediation NAT Gateway EIP"
  }
}

# Create a route table for the private subnet
resource "aws_route_table" "remediation_private_rt" {
  vpc_id = aws_vpc.remediation_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.remediation_nat_gateway.id
  }
  tags = {
    Name = "Remediation Private Route Table"
  }
}

# Associate the private subnet with the private route table
resource "aws_route_table_association" "remediation_private_subnet_rt_association" {
  subnet_id      = aws_subnet.remediation_private_subnet.id
  route_table_id = aws_route_table.remediation_private_rt.id
}
