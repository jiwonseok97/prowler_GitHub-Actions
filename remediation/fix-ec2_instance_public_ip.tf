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
  name_prefix = "restricted-"
  vpc_id      = data.aws_instance.problematic_instance.vpc_id

  # Allow SSH access from a bastion host
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"] # Replace with your bastion host's IP range
  }

  # Allow necessary application traffic
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.web_alb_sg.id] # Reference the ALB security group
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create a new Application Load Balancer security group
resource "aws_security_group" "web_alb_sg" {
  name_prefix = "web-alb-"
  vpc_id      = data.aws_instance.problematic_instance.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.restricted_sg.id] # Reference the instance security group
  }
}

# Create a new Application Load Balancer
resource "aws_lb" "web_alb" {
  name               = "web-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web_alb_sg.id]
  subnets            = data.aws_instance.problematic_instance.subnet_id
}

# Create a new target group for the Application Load Balancer
resource "aws_lb_target_group" "web_tg" {
  name        = "web-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = data.aws_instance.problematic_instance.vpc_id
  target_type = "instance"
}

# Create a new listener for the Application Load Balancer
resource "aws_lb_listener" "web_listener" {
  load_balancer_arn = aws_lb.web_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}

# Associate the EC2 instance with the Application Load Balancer target group
resource "aws_lb_target_group_attachment" "web_tg_attachment" {
  target_group_arn = aws_lb_target_group.web_tg.arn
  target_id        = data.aws_instance.problematic_instance.id
  port             = 80
}


This Terraform code addresses the security finding by:

1. Creating a new security group (`restricted_sg`) that allows only necessary inbound traffic, such as SSH access from a bastion host and application traffic from the Application Load Balancer.
2. Creating a new Application Load Balancer security group (`web_alb_sg`) that allows inbound HTTP traffic from the internet and outbound traffic to the instance security group.
3. Creating a new Application Load Balancer (`web_alb`) and a target group (`web_tg`)