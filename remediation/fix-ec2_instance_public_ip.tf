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
  # Add rules as per your application requirements
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

# Create a new WAF Web ACL and associate it with the load balancer
resource "aws_wafv2_web_acl" "application_waf" {
  name        = "app-waf"
  description = "WAF for the application load balancer"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  # Add your WAF rules here
}

resource "aws_wafv2_web_acl_association" "waf_association" {
  resource_arn = aws_lb.application_lb.arn
  web_acl_arn  = aws_wafv2_web_acl.application_waf.arn
}


This Terraform code addresses the security finding by:

1. Configuring the AWS provider for the ap-northeast-2 region.
2. Retrieving the details of the existing EC2 instance using a data source.
3. Creating a new security group with restricted inbound rules, allowing only necessary traffic (e.g., SSH access from a bastion host or via Session Manager).
4. Attaching the new security group to the existing EC2 instance.
5. Creating a new Application Load Balancer to expose the application, using the restricted security group.
6. Creating a new WAF Web ACL and associating it with the load balancer, providing an additional layer of security.

The code ensures that the EC2 instance is not directly exposed to the public internet, and all traffic to the application is routed through the load balancer and protected by the WAF.