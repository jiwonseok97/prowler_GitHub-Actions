# Create an interface VPC endpoint for the EC2 service
resource "aws_vpc_endpoint" "remediation_ec2_endpoint" {
  vpc_id            = "vpc-0565167ce4f7cc871"
  service_name      = "com.amazonaws.ap-northeast-2.ec2"
  vpc_endpoint_type = "Interface"
  private_dns_enabled = true

  security_group_ids = [
    aws_security_group.remediation_ec2_endpoint_sg.id
  ]

  subnet_ids = [
    # Add the subnet IDs where you want to create the VPC endpoint
    "subnet-0123456789abcdef1",
    "subnet-0123456789abcdef2",
    "subnet-0123456789abcdef3"
  ]
}

# Create a security group for the VPC endpoint
resource "aws_security_group" "remediation_ec2_endpoint_sg" {
  name        = "remediation-ec2-endpoint-sg"
  description = "Security group for the EC2 VPC endpoint"
  vpc_id      = "vpc-0565167ce4f7cc871"
}

# Add a restrictive policy to the VPC endpoint
resource "aws_vpc_endpoint_policy" "remediation_ec2_endpoint_policy" {
  vpc_endpoint_id = aws_vpc_endpoint.remediation_ec2_endpoint.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Principal = "*",
        Action = [
          "ec2:Describe*"
        ],
        Resource = "*"
      }
    ]
  })
}