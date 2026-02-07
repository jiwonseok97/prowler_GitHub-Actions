# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Create a new VPC in the ap-northeast-1 region
resource "aws_vpc" "ap_northeast_1" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "ap-northeast-1 VPC"
  }
}

# Create a new VPC in the ap-northeast-2 region
resource "aws_vpc" "ap_northeast_2" {
  cidr_block = "10.1.0.0/16"

  tags = {
    Name = "ap-northeast-2 VPC"
  }
}

# Create a new internet gateway for the ap-northeast-1 VPC
resource "aws_internet_gateway" "ap_northeast_1_igw" {
  vpc_id = aws_vpc.ap_northeast_1.id

  tags = {
    Name = "ap-northeast-1 IGW"
  }
}

# Create a new internet gateway for the ap-northeast-2 VPC
resource "aws_internet_gateway" "ap_northeast_2_igw" {
  vpc_id = aws_vpc.ap_northeast_2.id

  tags = {
    Name = "ap-northeast-2 IGW"
  }
}

# Create a new route table for the ap-northeast-1 VPC
resource "aws_route_table" "ap_northeast_1_rt" {
  vpc_id = aws_vpc.ap_northeast_1.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ap_northeast_1_igw.id
  }

  tags = {
    Name = "ap-northeast-1 Route Table"
  }
}

# Create a new route table for the ap-northeast-2 VPC
resource "aws_route_table" "ap_northeast_2_rt" {
  vpc_id = aws_vpc.ap_northeast_2.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ap_northeast_2_igw.id
  }

  tags = {
    Name = "ap-northeast-2 Route Table"
  }
}