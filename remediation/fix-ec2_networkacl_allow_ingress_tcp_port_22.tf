# Modify the existing Network ACL to restrict SSH access to trusted sources
resource "aws_network_acl" "remediation_network_acl" {
  vpc_id     = data.aws_vpc.current.id
  subnet_ids = [data.aws_subnet.current.id]

  ingress {
    from_port   = 22
    to_port     = 22
    rule_no    = 100
    protocol    = "tcp"
    cidr_block  = "10.0.0.0/16" # Replace with your trusted CIDR block
    action      = "allow"
  }

  egress {
    from_port   = 0
    to_port     = 0
    rule_no    = 100
    protocol    = "-1"
    cidr_block  = "0.0.0.0/0"
    action      = "allow"
  }

  tags = {
    Name = "remediation_network_acl"
  }
}

# Use data sources to reference existing resources
data "aws_vpc" "current" {
  id = "vpc-0123456789abcdef" # Replace with your VPC ID
}

data "aws_subnet" "current" {
  id = "subnet-0123456789abcdef" # Replace with your subnet ID
}