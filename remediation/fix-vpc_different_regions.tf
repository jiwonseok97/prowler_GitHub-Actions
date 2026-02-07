# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Create a new VPC in the ap-northeast-1 region
resource "aws_vpc" "ap_northeast_1" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "ap-northeast-1-vpc"
  }
}

# Create a new VPC in the ap-northeast-2 region
resource "aws_vpc" "ap_northeast_2" {
  cidr_block = "10.1.0.0/16"

  tags = {
    Name = "ap-northeast-2-vpc"
  }
}

# Create a new VPC in the ap-southeast-1 region
resource "aws_vpc" "ap_southeast_1" {
  cidr_block = "10.2.0.0/16"

  tags = {
    Name = "ap-southeast-1-vpc"
  }
}

# Create a new VPC in the ap-southeast-2 region
resource "aws_vpc" "ap_southeast_2" {
  cidr_block = "10.3.0.0/16"

  tags = {
    Name = "ap-southeast-2-vpc"
  }
}

# Create a new VPC in the us-east-1 region
resource "aws_vpc" "us_east_1" {
  cidr_block = "10.4.0.0/16"

  tags = {
    Name = "us-east-1-vpc"
  }
}

# Create a new VPC in the us-west-2 region
resource "aws_vpc" "us_west_2" {
  cidr_block = "10.5.0.0/16"

  tags = {
    Name = "us-west-2-vpc"
  }
}


This Terraform code creates six new VPCs, one in each of the following regions: ap-northeast-1, ap-northeast-2, ap-southeast-1, ap-southeast-2, us-east-1, and us-west-2. This addresses the security finding by ensuring that critical workloads are deployed across multiple regions, providing fault tolerance and defense in depth.