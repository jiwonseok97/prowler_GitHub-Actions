# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Get the existing VPC details
data "aws_vpc" "existing_vpc" {
  id = "vpc-0565167ce4f7cc871"
}

# Create two new subnets in different Availability Zones
resource "aws_subnet" "new_subnet_1" {
  vpc_id            = data.aws_vpc.existing_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-northeast-2a"
}

resource "aws_subnet" "new_subnet_2" {
  vpc_id            = data.aws_vpc.existing_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-northeast-2c"
}

# Associate the new subnets with the existing VPC
resource "aws_route_table_association" "new_subnet_1_association" {
  subnet_id      = aws_subnet.new_subnet_1.id
  route_table_id = data.aws_vpc.existing_vpc.main_route_table_id
}

resource "aws_route_table_association" "new_subnet_2_association" {
  subnet_id      = aws_subnet.new_subnet_2.id
  route_table_id = data.aws_vpc.existing_vpc.main_route_table_id
}


This Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Retrieves the details of the existing VPC using the `data.aws_vpc` data source.
3. Creates two new subnets, one in `ap-northeast-2a` and the other in `ap-northeast-2c`, to distribute the subnets across multiple Availability Zones.
4. Associates the new subnets with the existing VPC's main route table.

By adding these new subnets in different Availability Zones, the VPC will now have subnets in multiple AZs, which is the recommended configuration for high availability.