# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Get the existing VPC details
data "aws_vpc" "existing_vpc" {
  id = "vpc-0565167ce4f7cc871"
}

# Create a new public subnet
resource "aws_subnet" "public_subnet" {
  vpc_id            = data.aws_vpc.existing_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "Public Subnet"
  }
}

# Create a new private subnet
resource "aws_subnet" "private_subnet" {
  vpc_id            = data.aws_vpc.existing_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-northeast-2b"

  tags = {
    Name = "Private Subnet"
  }
}

# Create a new internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = data.aws_vpc.existing_vpc.id

  tags = {
    Name = "Internet Gateway"
  }
}

# Create a new route table for the public subnet
resource "aws_route_table" "public_route_table" {
  vpc_id = data.aws_vpc.existing_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "Public Route Table"
  }
}

# Associate the public subnet with the public route table
resource "aws_route_table_association" "public_subnet_route_table_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

# Create a new route table for the private subnet
resource "aws_route_table" "private_route_table" {
  vpc_id = data.aws_vpc.existing_vpc.id

  tags = {
    Name = "Private Route Table"
  }
}

# Associate the private subnet with the private route table
resource "aws_route_table_association" "private_subnet_route_table_association" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_route_table.id
}


This Terraform code addresses the security finding by creating a new public subnet and a new private subnet within the existing VPC. It also creates an internet gateway and configures the route tables to ensure that the public subnet has access to the internet, while the private subnet is isolated from the internet.