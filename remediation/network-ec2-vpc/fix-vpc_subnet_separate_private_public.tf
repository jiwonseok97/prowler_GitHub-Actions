#Create a new public subnet in the existing VPC
resource "aws_subnet" "remediation_public_subnet" {
  vpc_id            = "vpc-0565167ce4f7cc871"
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "remediation-public-subnet"
  }
}

#Create a new private subnet in the existing VPC
resource "aws_subnet" "remediation_private_subnet" {
  vpc_id            = "vpc-0565167ce4f7cc871"
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-northeast-2b"

  tags = {
    Name = "remediation-private-subnet"
  }
}

#Create a new internet gateway and attach it to the VPC
resource "aws_internet_gateway" "remediation_igw" {
  vpc_id = "vpc-0565167ce4f7cc871"

  tags = {
    Name = "remediation-internet-gateway"
  }
}

#Create a new route table for the public subnet and associate it with the internet gateway
resource "aws_route_table" "remediation_public_rt" {
  vpc_id = "vpc-0565167ce4f7cc871"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.remediation_igw.id
  }

  tags = {
    Name = "remediation-public-route-table"
  }
}

resource "aws_route_table_association" "remediation_public_subnet_rt_association" {
  subnet_id      = aws_subnet.remediation_public_subnet.id
  route_table_id = aws_route_table.remediation_public_rt.id
}

#Create a new NAT gateway and elastic IP for the private subnet
resource "aws_eip" "remediation_nat_eip" {
  count = 1
}

resource "aws_nat_gateway" "remediation_nat_gw" {
  allocation_id = aws_eip.remediation_nat_eip[0].id
  subnet_id     = aws_subnet.remediation_public_subnet.id

  tags = {
    Name = "remediation-nat-gateway"
  }
}

#Create a new route table for the private subnet and associate it with the NAT gateway
resource "aws_route_table" "remediation_private_rt" {
  vpc_id = "vpc-0565167ce4f7cc871"

  route {
    cidr_block     = "0.0.0.0/0"
    gateway_id     = aws_nat_gateway.remediation_nat_gw.id
    nat_gateway_id = aws_nat_gateway.remediation_nat_gw.id
  }

  tags = {
    Name = "remediation-private-route-table"
  }
}

resource "aws_route_table_association" "remediation_private_subnet_rt_association" {
  subnet_id      = aws_subnet.remediation_private_subnet.id
  route_table_id = aws_route_table.remediation_private_rt.id
}
