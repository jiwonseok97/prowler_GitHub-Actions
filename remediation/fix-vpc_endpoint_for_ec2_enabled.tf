# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Create an interface VPC endpoint for the EC2 service
resource "aws_vpc_endpoint" "ec2" {
  vpc_id            = "vpc-0565167ce4f7cc871"
  service_name      = "com.amazonaws.ap-northeast-2.ec2"
  vpc_endpoint_type = "Interface"

  # Enable private DNS to keep calls on the AWS network
  private_dns_enabled = true

  # Apply a restrictive endpoint policy to limit access
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": [
        "ec2:Describe*"
      ],
      "Resource": "*"
    }
  ]
}
POLICY

  # Add security group rules to control inbound and outbound traffic
  security_group_ids = [aws_security_group.ec2_endpoint.id]
}

# Create a security group for the EC2 VPC endpoint
resource "aws_security_group" "ec2_endpoint" {
  name_prefix = "ec2-endpoint-"
  vpc_id      = "vpc-0565167ce4f7cc871"

  # Allow inbound traffic from the VPC
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]
  }

  # Allow outbound traffic to the VPC
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]
  }
}