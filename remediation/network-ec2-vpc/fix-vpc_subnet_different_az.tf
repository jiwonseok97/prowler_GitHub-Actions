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
  route_table_ids   = ["rtb-0123456789abcdef"]
}
