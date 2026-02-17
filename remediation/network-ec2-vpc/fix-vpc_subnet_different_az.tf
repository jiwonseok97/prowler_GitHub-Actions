# Create a new subnet in a different Availability Zone
resource "aws_subnet" "remediation_subnet" {
  vpc_id            = "vpc-0565167ce4f7cc871"
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-northeast-2b"

  tags = {
    Name = "remediation-subnet"
  }
}

# Associate the new subnet with the existing VPC
resource "aws_vpc_endpoint" "remediation_vpc_endpoint" {
  vpc_id            = "vpc-0565167ce4f7cc871"
  service_name      = "com.amazonaws.ap-northeast-2.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.remediation_route_table.id]

  tags = {
    Name = "remediation-vpc-endpoint"
  }
}

# Create a new route table and associate it with the new subnet
resource "aws_route_table" "remediation_route_table" {
  vpc_id = "vpc-0565167ce4f7cc871"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "igw-0a12345b6c7890def"
  }

  tags = {
    Name = "remediation-route-table"
  }
}

resource "aws_route_table_association" "remediation_route_table_association" {
  subnet_id      = aws_subnet.remediation_subnet.id
  route_table_id = aws_route_table.remediation_route_table.id
}
