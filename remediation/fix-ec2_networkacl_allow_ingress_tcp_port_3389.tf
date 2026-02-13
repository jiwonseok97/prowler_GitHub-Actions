# Modify the existing Network ACL to restrict RDP access
resource "aws_network_acl" "remediation_network_acl" {
  vpc_id     = data.aws_vpc.default.id
  subnet_ids = data.aws_subnets.default.ids
  
  ingress {
    from_port   = 0
    to_port     = 0
    rule_no    = 100
    action     = "allow"
    protocol    = "-1"
    cidr_block = "0.0.0.0/0"
  }

  egress {
    from_port   = 0
    to_port     = 0 
    rule_no    = 100
    action     = "allow"
    protocol    = "-1"
    cidr_block = "0.0.0.0/0"
  }

  # Restrict RDP access to specific IP ranges
  ingress {
    from_port   = 3389
    to_port     = 3389
    rule_no    = 200
    action     = "deny"
    protocol    = "tcp"
    cidr_block = "0.0.0.0/0"
  }

  tags = {
    Name = "remediation_network_acl"
  }
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}