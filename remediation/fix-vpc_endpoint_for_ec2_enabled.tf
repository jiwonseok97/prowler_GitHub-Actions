# Create an interface VPC endpoint for the EC2 service
resource "aws_vpc_endpoint" "remediation_ec2_endpoint" {
  vpc_id = "vpc-0565167ce4f7cc871"
  service_name      = "com.amazonaws.ap-northeast-2.ec2"
  vpc_endpoint_type = "Interface"
  private_dns_enabled = true

  security_group_ids = tolist(data.aws_security_groups.existing_vpc_security_groups.ids)
}

# Look up the existing VPC security groups
data "aws_security_groups" "existing_vpc_security_groups" {
}