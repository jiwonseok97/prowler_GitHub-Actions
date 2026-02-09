# Create a new network ACL to restrict SSH access to trusted sources
resource "aws_network_acl" "remediation_network_acl" {
  vpc_id = data.aws_vpc.current.id
  subnet_ids = [data.aws_subnet.current.id]

  ingress {
    rule_no    = 100
    action     = "allow"
    from_port  = 22
    to_port    = 22
    protocol   = "tcp"
    cidr_block = "10.0.0.0/16" # Replace with your trusted CIDR block
  }

  egress {
    rule_no    = 100
    action     = "allow"
    from_port  = 0
    to_port    = 0
    protocol   = "-1"
    cidr_block = "0.0.0.0/0"
  }
}

# Lookup the current VPC and subnet information
data "aws_vpc" "current" {
  id = "vpc-0123456789abcdef" # Replace with your VPC ID
}

data "aws_subnet" "current" {
  id = "subnet-0123456789abcdef" # Replace with your subnet ID
}