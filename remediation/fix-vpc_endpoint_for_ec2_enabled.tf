# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Create an interface VPC endpoint for the EC2 service
resource "aws_vpc_endpoint" "ec2" {
  vpc_id            = "vpc-0565167ce4f7cc871"
  service_name      = "com.amazonaws.ap-northeast-2.ec2"
  vpc_endpoint_type = "Interface"
  private_dns_enabled = true

  # Apply a restrictive endpoint policy to limit access
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": "ec2:*",
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "aws:sourceVpce": "${aws_vpc_endpoint.ec2.id}"
        }
      }
    }
  ]
}
POLICY

  # Reduce reliance on public egress and layer controls for defense in depth
  security_group_ids = ["sg-0123456789abcdef"]
}