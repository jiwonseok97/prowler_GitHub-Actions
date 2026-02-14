# Create a new private subnet
resource "aws_subnet" "remediation_private_subnet" {
  vpc_id            = "vpc-0565167ce4f7cc871"
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "remediation-private-subnet"
  }
}

# Create a new public subnet
resource "aws_subnet" "remediation_public_subnet" {
  vpc_id                  = "vpc-0565167ce4f7cc871"
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-northeast-2b"
  map_public_ip_on_launch = true

  tags = {
    Name = "remediation-public-subnet"
  }
}

# Create a new internet gateway
resource "aws_internet_gateway" "remediation_igw" {
  vpc_id = "vpc-0565167ce4f7cc871"

  tags = {
    Name = "remediation-igw"
  }
}

# Create a new route table for the public subnet
resource "aws_route_table" "remediation_public_rt" {
  vpc_id = "vpc-0565167ce4f7cc871"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.remediation_igw.id
  }

  tags = {
    Name = "remediation-public-rt"
  }
}

# Associate the public subnet with the public route table
resource "aws_route_table_association" "remediation_public_subnet_rt_association" {
  subnet_id      = aws_subnet.remediation_public_subnet.id
  route_table_id = aws_route_table.remediation_public_rt.id
}

# Create a new route table for the private subnet
resource "aws_route_table" "remediation_private_rt" {
  vpc_id = "vpc-0565167ce4f7cc871"

  tags = {
    Name = "remediation-private-rt"
  }
}

# Associate the private subnet with the private route table
resource "aws_route_table_association" "remediation_private_subnet_rt_association" {
  subnet_id      = aws_subnet.remediation_private_subnet.id
  route_table_id = aws_route_table.remediation_private_rt.id
}