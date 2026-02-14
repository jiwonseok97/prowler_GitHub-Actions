# Modify the existing Network ACL to restrict SSH access from the internet
resource "aws_network_acl" "remediation_network_acl" {
  vpc_id     = data.aws_subnet.example.vpc_id
  subnet_ids = [data.aws_subnet.example.id]
  
  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    rule_no    = 100
    protocol    = "-1"
    cidr_block = "0.0.0.0/0"
    action     = "allow"
  }

  # Deny inbound SSH access from the internet
  ingress {
    from_port   = 22
    to_port     = 22
    rule_no    = 100
    protocol    = "tcp"
    cidr_block = "0.0.0.0/0"
    action     = "deny"
  }

  # Allow all other inbound traffic
  ingress {
    from_port   = 0
    to_port     = 0
    rule_no    = 200
    protocol    = "-1"
    cidr_block = "0.0.0.0/0"
    action     = "allow"
  }

  tags = {
    Name = "remediation_network_acl"
  }
}

# Use a data source to look up the existing subnet
data "aws_subnet" "example" {
  id = "subnet-0572e1ab82993bb20"
}