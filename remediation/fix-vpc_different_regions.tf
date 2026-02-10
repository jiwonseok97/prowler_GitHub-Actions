# Create a new VPC in the ap-northeast-2 region
resource "aws_vpc" "remediation_vpc" {
  cidr_block = "10.0.0.0/16"
}

# Create a new subnet in the ap-northeast-2 region
resource "aws_subnet" "remediation_subnet" {
  vpc_id     = aws_vpc.remediation_vpc.id
  cidr_block = "10.0.1.0/24"
}

# Create a new internet gateway and attach it to the VPC
resource "aws_internet_gateway" "remediation_igw" {
  vpc_id = aws_vpc.remediation_vpc.id
}

# Create a new route table and associate it with the subnet
resource "aws_route_table" "remediation_route_table" {
  vpc_id = aws_vpc.remediation_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.remediation_igw.id
  }
}

resource "aws_route_table_association" "remediation_route_table_association" {
  subnet_id      = aws_subnet.remediation_subnet.id
  route_table_id = aws_route_table.remediation_route_table.id
}