# Modify the existing security group to apply least privilege
resource "aws_security_group" "remediation_sg" {
  name = "remediation-sg"
  description = "Remediated security group"
  vpc_id      = data.aws_vpc.default.id

  # Restrict inbound to required sources
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  # Minimize egress
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Use data source to look up the existing security group
data "aws_security_group" "existing_sg" {
  id = "sg-0a48adc1c033afb1f"
}

# Replace the existing security group with the remediated one
resource "aws_instance" "remediation_example" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"

  vpc_security_group_ids = [aws_security_group.remediation_sg.id]
}

data "aws_vpc" "default" {
  default = true
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}