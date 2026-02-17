# Create a VPC endpoint for the EC2 service
resource "aws_vpc_endpoint" "remediation_ec2_endpoint" {
  vpc_id              = "vpc-0565167ce4f7cc871"
  service_name        = "com.amazonaws.ap-northeast-2.ec2"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  security_group_ids = [
    # Replace with the appropriate security group IDs
    var.security_group_id,
    var.security_group_id
  ]

  subnet_ids = [
    # Replace with the appropriate subnet IDs
    var.subnet_id,
    var.subnet_id
  ]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow",
        Principal = "*",
        Action    = "ec2:*",
        Resource  = "*"
      }
    ]
  })
}

variable "subnet_id" {
  description = "Target subnet ID"
  type        = string
  default     = ""
}

variable "subnet_ids" {
  description = "Target subnet IDs"
  type        = list(string)
  default     = []
}

variable "security_group_id" {
  description = "Target security group ID"
  type        = string
  default     = ""
}
