# Create an interface VPC endpoint for the EC2 service
resource "aws_vpc_endpoint" "remediation_ec2_endpoint" {
  vpc_id            = "vpc-0565167ce4f7cc871"
  service_name      = "com.amazonaws.ap-northeast-2.ec2"
  vpc_endpoint_type = "Interface"
  private_dns_enabled = true

  security_group_ids = [
    # Add the appropriate security group IDs for the VPC endpoint
    "sg-0123456789abcdef",
    "sg-fedcba9876543210",
  ]

  subnet_ids = [
    # Add the appropriate subnet IDs for the VPC endpoint
    "subnet-0123456789abcdef",
    "subnet-fedcba9876543210",
  ]
}

# Apply a restrictive endpoint policy to the VPC endpoint
resource "aws_vpc_endpoint_policy" "remediation_ec2_endpoint_policy" {
  vpc_endpoint_id = aws_vpc_endpoint.remediation_ec2_endpoint.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Principal = "*",
        Action = [
          "ec2:Describe*",
        ],
        Resource = "*"
      }
    ]
  })
}