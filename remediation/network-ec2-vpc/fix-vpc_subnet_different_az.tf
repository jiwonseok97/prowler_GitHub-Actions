# Create a new subnet in a different Availability Zone
resource "aws_subnet" "remediation_subnet" {
  vpc_id            = "vpc-0565167ce4f7cc871"
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-northeast-2b"

  tags = {
    Name = "remediation-subnet"
  }
}

# Update the route table to include the new subnet
resource "aws_route_table_association" "remediation_route_table_association" {
  subnet_id      = aws_subnet.remediation_subnet.id
  route_table_id = data.aws_route_table.existing_route_table.id
}

data "aws_route_table" "existing_route_table" {
  vpc_id = "vpc-0565167ce4f7cc871"
}
