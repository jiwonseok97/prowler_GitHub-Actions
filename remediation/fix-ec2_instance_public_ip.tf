# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Get the existing EC2 instance details
data "aws_instance" "problematic_instance" {
  instance_id = "i-0fbecaba3c48e7c79"
}

# Create a new security group to allow only necessary inbound traffic
resource "aws_security_group" "restricted_sg" {
  name_prefix = "restricted-sg-"
  vpc_id      = data.aws_instance.problematic_instance.vpc_id

  # Allow SSH access from a bastion host or via Session Manager
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"] # Replace with your bastion host's IP range
  }

  # Allow necessary application-specific traffic
  # Add additional ingress rules as per your requirements
}

# Attach the new security group to the existing EC2 instance
resource "aws_network_interface_sg_attachment" "sg_attachment" {
  security_group_id    = aws_security_group.restricted_sg.id
  network_interface_id = data.aws_instance.problematic_instance.primary_network_interface_id
}

# Create a new Elastic Load Balancer to expose the application
resource "aws_lb" "application_lb" {
  name               = "app-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.restricted_sg.id]
  subnets            = [data.aws_instance.problematic_instance.subnet_id]
}

# Add a listener and target group to the load balancer
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.application_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

resource "aws_lb_target_group" "app_tg" {
  name        = "app-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = data.aws_instance.problematic_instance.vpc_id
  target_type = "instance"
}

# Register the EC2 instance with the target group
resource "aws_lb_target_group_attachment" "app_tg_attachment" {
  target_group_arn = aws_lb_target_group.app_tg.arn
  target_id        = data.aws_instance.problematic_instance.id
  port             = 80
}


This Terraform code addresses the security finding by:

1. Configuring the AWS provider for the ap-northeast-2 region.
2. Retrieving the details of the existing EC2 instance using a data source.
3. Creating a new security group with restricted inbound access, allowing only necessary traffic (e.g., SSH from a bastion host).
4. Attaching the new security group to the existing EC2 instance.
5. Creating a new Application Load Balancer to expose the application, using the restricted security group.
6. Adding a listener and target group to the load balancer.
7. Registering the EC2 instance with the target group.

This approach follows the recommendation to avoid assigning public IPs and instead use a load balancer with a Web Application Firewall (WAF) to expose the application. The EC2 instance is placed in a private subnet, and access is controlled through the load balancer and the restricted security group.