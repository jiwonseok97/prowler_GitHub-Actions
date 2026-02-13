# Create two new subnets in different Availability Zones
resource "aws_subnet" "remediation_subnet_1" {
  vpc_id            = "vpc-0565167ce4f7cc871"
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-northeast-2a"
}

resource "aws_subnet" "remediation_subnet_2" {
  vpc_id            = "vpc-0565167ce4f7cc871"
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-northeast-2b"
}

# Update the existing subnets to be in different Availability Zones
resource "aws_subnet" "remediation_existing_subnet_1" {
  vpc_id            = "vpc-0565167ce4f7cc871"
  cidr_block        = "10.0.0.0/24"
  availability_zone = "ap-northeast-2a"
}

resource "aws_subnet" "remediation_existing_subnet_2" {
  vpc_id            = "vpc-0565167ce4f7cc871"
  cidr_block        = "10.0.3.0/24"
  availability_zone = "ap-northeast-2b"
}