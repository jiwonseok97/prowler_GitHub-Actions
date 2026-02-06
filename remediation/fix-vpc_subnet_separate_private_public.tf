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
resource "aws_route_table_association" "public_subnet_association" {
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
resource "aws_route_table_association" "private_subnet_association" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_route_table.id
}


This Terraform code does the following:

1. Configures the AWS provider for the ap-northeast-2 region.
2. Retrieves the existing VPC details using a data source.
3. Creates a new public subnet within the existing VPC.
4. Creates a new private subnet within the existing VPC.
5. Creates a new internet gateway for the VPC.
6. Creates a new route table for the public subnet, with a route to the internet gateway.
7. Associates the public subnet with the public route table.
8. Creates a new route table for the private subnet.
9. Associates the private subnet with the private route table.

This setup ensures that the VPC has both public and private subnets, with the public subnet having access to the internet through the internet gateway, and the private subnet being isolated from the internet.