resource "aws_vpc_endpoint" "remediation_ec2_endpoint" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ec2"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  security_group_ids = [
    var.security_group_id
  ]

  subnet_ids = [
    var.subnet_id,
    var.subnet_id
  ]
}

resource "aws_vpc_endpoint_policy" "remediation_ec2_endpoint_policy" {
  vpc_endpoint_id = aws_vpc_endpoint.remediation_ec2_endpoint.id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": "ec2:Describe*",
      "Resource": "*"
    }
  ]
}
POLICY
}





variable "vpc_id" {
  description = "Existing VPC identifier"
  type        = string
  default     = ""
}

variable "security_group_id" {
  description = "Existing aws_security_group identifier"
  type        = string
  default     = ""
}

variable "subnet_id_1" {
  description = "Existing aws_subnet identifier"
  type        = string
  default     = ""
}

variable "subnet_id_2" {
  description = "Existing aws_subnet identifier"
  type        = string
  default     = ""
}

variable "subnet_id" {
  description = "Target subnet ID"
  type        = string
  default     = ""
}
