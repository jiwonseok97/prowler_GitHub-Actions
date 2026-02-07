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

  # Allow SSH access from a bastion host
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"] # Replace with your bastion host's IP range
  }

  # Allow HTTP/HTTPS access from a web application load balancer
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.web_alb_sg.id]
  }
  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.web_alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create a security group for the web application load balancer
resource "aws_security_group" "web_alb_sg" {
  name_prefix = "web-alb-sg-"
  vpc_id      = data.aws_instance.problematic_instance.vpc_id

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

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Attach the new security group to the existing EC2 instance
resource "aws_network_interface_sg_attachment" "sg_attachment" {
  security_group_id    = aws_security_group.restricted_sg.id
  network_interface_id = data.aws_instance.problematic_instance.primary_network_interface_id
}

# Create a web application load balancer to expose the EC2 instance
resource "aws_lb" "web_alb" {
  name               = "web-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web_alb_sg.id]
  subnets            = data.aws_instance.problematic_instance.subnet_id
}

# Create a target group for the web application load balancer
resource "aws_lb_target_group" "web_tg" {
  name        = "web-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = data.aws_instance.problematic_instance.vpc_id
  target_type = "instance"

  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# Add the EC2 instance to the target group
resource "aws_lb_target_group_attachment" "web_tg_attachment" {
  target_group_arn = aws_lb_target_group.web_tg.arn
  target_id        = data.aws_instance.problematic_instance.id
  port             = 80
}