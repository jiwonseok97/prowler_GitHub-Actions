# Modify the existing EC2 instance to use an HVM/Nitro-based AMI
resource "aws_instance" "remediation_ec2_instance" {
  ami                    = "ami-0b0af3577fe5e3532" # Replace with a suitable HVM/Nitro AMI
  instance_type          = "t3.micro"
  subnet_id              = tolist(data.aws_subnets.default.ids)[0]
  vpc_security_group_ids = tolist(data.aws_security_groups.default.ids)

  tags = {
    Name = "remediation-ec2-instance"
  }
}

# Use data sources to look up existing resources
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
}

data "aws_security_groups" "default" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
}

variable "vpc_id" {
  description = "Target VPC ID"
  type        = string
  default     = ""
}
