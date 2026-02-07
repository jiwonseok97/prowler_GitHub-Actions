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

  # Allow only necessary inbound traffic (e.g., SSH from bastion, HTTP/HTTPS from load balancer)
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
    security_groups = [aws_security_group.load_balancer_sg.id] # Allow HTTP from the load balancer
  }

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.load_balancer_sg.id] # Allow HTTPS from the load balancer
  }

  # Allow necessary outbound traffic (e.g., to the internet via NAT gateway)
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

# Create a new load balancer security group
resource "aws_security_group" "load_balancer_sg" {
  name_prefix = "lb-sg-"
  vpc_id      = data.aws_instance.problematic_instance.vpc_id

  # Allow inbound HTTP and HTTPS traffic
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow necessary outbound traffic
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

# Create a new Network Load Balancer
resource "aws_lb" "application_load_balancer" {
  name               = "app-lb"
  internal           = false
  load_balancer_type = "network"
  security_groups    = [aws_security_group.load_balancer_sg.id]
  subnets            = [data.aws_instance.problematic_instance.subnet_id]
}

# Create a new target group for the load balancer
resource "aws_lb_target_group" "app_target_group" {
  name        = "app-tg"
  port        = 80
  protocol    = "TCP"
  vpc_id      = data.aws_instance.problematic_instance.vpc_id
  target_type = "instance"
}

# Create a new listener for the load balancer
resource "aws_lb_listener" "app_listener" {
  load_balancer_arn = aws_lb.application_load_balancer.arn
  port              = 80
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_target_group.arn
  }
}

# Associate the EC2 instance with the target group
resource "aws_lb_target_group_attachment" "app_instance_attachment" {
  target_group_arn = aws_lb_target_group