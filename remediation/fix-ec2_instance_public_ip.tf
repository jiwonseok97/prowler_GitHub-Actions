# Modify the existing EC2 instance to remove the public IP
resource "aws_instance" "remediation_ec2_instance" {
  ami           = "ami-0b7546d835a9b606e"
  instance_type = "t2.micro"
  subnet_id     = "subnet-0123456789abcdef"

  # Ensure the instance is in a private subnet without a public IP
  associate_public_ip_address = false

  # Add other required configuration for the EC2 instance
}

# Create a new NAT Gateway in the public subnet to enable internet access
# for instances in the private subnet
resource "aws_nat_gateway" "remediation_nat_gateway" {
  allocation_id = "eipalloc-0123456789abcdef"
  subnet_id     = "subnet-fedcba9876543210"
}

# Update the route table for the private subnet to route internet traffic
# through the NAT Gateway
resource "aws_route_table" "remediation_private_route_table" {
  vpc_id = "vpc-0123456789abcdef"

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.remediation_nat_gateway.id
  }
}

# Associate the private subnet with the updated route table
resource "aws_route_table_association" "remediation_private_subnet_route_table_association" {
  subnet_id      = "subnet-0123456789abcdef"
  route_table_id = aws_route_table.remediation_private_route_table.id
}

# Create a new security group to allow only necessary inbound traffic
# to the EC2 instance, e.g., via a load balancer
resource "aws_security_group" "remediation_ec2_security_group" {
  name_prefix = "remediation-"
  vpc_id      = "vpc-0123456789abcdef"

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = ["sg-0123456789abcdef"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Attach the new security group to the EC2 instance
resource "aws_network_interface_sg_attachment" "remediation_ec2_security_group_attachment" {
  security_group_id    = aws_security_group.remediation_ec2_security_group.id
  network_interface_id = aws_instance.remediation_ec2_instance.primary_network_interface_id
}