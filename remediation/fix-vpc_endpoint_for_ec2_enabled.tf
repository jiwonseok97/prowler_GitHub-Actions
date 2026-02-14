# Create an interface VPC endpoint for the EC2 service
resource "aws_vpc_endpoint" "remediation_ec2_endpoint" {
  vpc_id = "vpc-0565167ce4f7cc871"
  service_name      = "com.amazonaws.ap-northeast-2.ec2"
  vpc_endpoint_type = "Interface"
  private_dns_enabled = true

  security_group_ids = [
    # Use existing security group IDs for the VPC
    data.aws_security_groups.vpc_security_groups.ids[0],
    data.aws_security_groups.vpc_security_groups.ids[1],
  ]

  subnet_ids = [
    # Use existing subnet IDs for the VPC
    data.aws_subnets.vpc_subnets.ids[0],
    data.aws_subnets.vpc_subnets.ids[1],
  ]
}

# Use data sources to look up existing VPC resources
data "aws_security_groups" "vpc_security_groups" {
}

data "aws_subnets" "vpc_subnets" {
}