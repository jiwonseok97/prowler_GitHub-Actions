# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Get the existing EC2 instance details
data "aws_instance" "problematic_instance" {
  instance_id = "i-0fbecaba3c48e7c79"
}

# Create a new security group to allow only necessary traffic
resource "aws_security_group" "restricted_sg" {
  name_prefix = "restricted-sg-"
  vpc_id      = data.aws_instance.problematic_instance.vpc_id

  # Allow only necessary inbound traffic (e.g., SSH from bastion, web traffic from load balancer)
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    cidr_blocks     = ["10.0.0.0/16"] # Restrict SSH access to a specific subnet
  }

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.web_alb_sg.id] # Allow web traffic from the load balancer
  }

  # Allow necessary outbound traffic (e.g., to the internet, to private resources)
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

# Create a new security group for the load balancer
resource "aws_security_group" "web_alb_sg" {
  name_prefix = "web-alb-sg-"
  vpc_id      = data.aws_instance.problematic_instance.vpc_id

  # Allow inbound web traffic to the load balancer
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"] # Allow web traffic from the internet
  }

  # Allow outbound traffic from the load balancer to the EC2 instance
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.restricted_sg.id]
  }
}

# Create a new network interface for the EC2 instance in a private subnet
resource "aws_network_interface" "private_nic" {
  subnet_id       = data.aws_instance.problematic_instance.subnet_id
  security_groups = [aws_security_group.restricted_sg.id]
}

# Attach the new network interface to the EC2 instance
resource "aws_network_interface_attachment" "nic_attachment" {
  instance_id          = data.aws_instance.problematic_instance.id
  network_interface_id = aws_network_interface.private_nic.id
  device_index         = 0
}


This Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Retrieves the existing EC2 instance details using the `data` source.
3. Creates a new security group `restricted_sg` to allow only necessary traffic (e.g., SSH from a bastion, web traffic from a load balancer).
4. Creates a new security group `web_alb_sg` for the load balancer, allowing inbound web traffic and outbound traffic to the EC2 instance.
5. Creates a new network interface `private_nic` in a private subnet and associates it with the `restricted_sg` security group.
6. Attaches the new network interface to the EC2 instance, effectively removing the public IP address.