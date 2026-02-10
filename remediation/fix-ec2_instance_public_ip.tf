# Modify the existing EC2 instance to remove the public IP
resource "aws_instance" "remediation_ec2_instance" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = "t2.micro"
  subnet_id     = data.aws_subnet.private_subnet.id
  associate_public_ip_address = false
}

# Create a new load balancer to expose the EC2 instance
resource "aws_lb" "remediation_load_balancer" {
  name               = "remediation-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.remediation_lb_security_group.id]
  subnets            = [data.aws_subnet.public_subnet.id, data.aws_subnet.public_subnet_2.id]
}

# Create a security group for the load balancer
resource "aws_security_group" "remediation_lb_security_group" {
  name        = "remediation-lb-security-group"
  description = "Security group for the remediation load balancer"
  vpc_id      = data.aws_vpc.main_vpc.id

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
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

# Create a target group for the load balancer
resource "aws_lb_target_group" "remediation_target_group" {
  name        = "remediation-target-group"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.main_vpc.id
  target_type = "instance"
}

# Create a listener for the load balancer
resource "aws_lb_listener" "remediation_listener" {
  load_balancer_arn = aws_lb.remediation_load_balancer.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.remediation_target_group.arn
  }
}

# Create a WAF web ACL and associate it with the load balancer
resource "aws_wafv2_web_acl" "remediation_waf_web_acl" {
  name        = "remediation-waf-web-acl"
  description = "WAF web ACL for the remediation load balancer"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      count {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "remediation-waf-web-acl"
      sampled_requests_enabled   = false
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = false
    metric_name                = "remediation-waf-web-acl"
    sampled_requests_enabled   = false
  }
}

resource "aws_wafv2_web_acl_association" "remediation_waf_web_acl_association" {
  resource_arn = aws_lb.remediation_load_balancer.arn
  web_acl_arn  = aws_wafv2_web_acl.remediation_waf_web_acl.arn
}

# Create a bastion host for administration
resource "aws_instance" "remediation_bastion_host" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = "t2.micro"
  subnet_id     = data.aws_subnet.public_subnet.id

  vpc_security_group_ids = [aws_security_group.remediation_bastion_security_group.id]
  key_name               = "my-key-pair"

  iam_instance_profile = aws_iam_instance_profile.remediation_bastion_instance_profile.name
}

# Create a security group for the bastion host
resource "aws_security_group" "remediation_bastion_security_group" {
  name        = "remediation-bastion-security-group"
  description = "Security group for the remediation bastion host"
  vpc_id      = data.aws_vpc.main_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

# Create an IAM role and instance profile for the bastion host
resource "aws_iam_role" "remediation_bastion_role" {
  name = "remediation-bastion-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "remediation_bastion_role_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.remediation_bastion_role.name
}

resource "aws_iam_instance_profile" "remediation_bastion_instance_profile" {
  name = "remediation-bastion-instance-profile"
  role = aws_iam_role.remediation_bastion_role.name
}

# Use data sources to look up existing resources
data "aws_vpc" "main_vpc" {
  id = "vpc-0123456789abcdef"
}

data "aws_subnet" "private_subnet" {
  id = "subnet-0123456789abcdef"
}

data "aws_subnet" "public_subnet" {
  id = "subnet-fedcba9876543210"
}

data "aws_subnet" "public_subnet_2" {
  id = "subnet-0fedcba9876543210"
}

data "aws_ami" "amazon_linux_2" {
  owners      = ["amazon"]
  name_regex  = "^amzn2-ami-hvm-2.*-x86_64-gp2$"
  most_recent = true
}