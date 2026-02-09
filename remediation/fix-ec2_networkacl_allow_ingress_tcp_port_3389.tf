# Modify the existing Network ACL to restrict RDP access from the internet
resource "aws_network_acl" "remediation_acl" {
  vpc_id     = data.aws_vpc.current.id
  subnet_ids = data.aws_subnet.private_subnets[*].id

  ingress {
    from_port   = 3389
    to_port     = 3389
    rule_no    = 100
    protocol    = "tcp"
    action      = "deny"
    cidr_block  = "0.0.0.0/0"
  }

  egress {
    from_port   = 0
    to_port     = 0 
    rule_no    = 100
    protocol    = "-1"
    action      = "allow"
    cidr_block  = "0.0.0.0/0"
  }

  tags = {
    Name = "remediation_acl"
  }
}

# Use data sources to reference existing VPC and subnet information
data "aws_vpc" "current" {
  id = "vpc-0123456789abcdef"
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.current.id]
  }

  filter {
    name   = "tag:Tier"
    values = ["private"]
  }
}

data "aws_subnet" "private_subnets" {
  count = length(data.aws_subnets.private.ids)
  id    = data.aws_subnets.private.ids[count.index]
}