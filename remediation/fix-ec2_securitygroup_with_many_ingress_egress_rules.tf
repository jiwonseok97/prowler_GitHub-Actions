# Modify the existing security group to reduce the number of rules
resource "aws_security_group" "remediation_sg" {
  name_prefix = "remediation-"
  vpc_id      = data.aws_security_group.existing.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "remediation-sg"
  }
}

# Use the modified security group in your resources
resource "aws_instance" "remediation_example" {
  ami           = "ami-0c94755bb95c71c99"
  instance_type = "t2.micro"

  vpc_security_group_ids = [
    aws_security_group.remediation_sg.id,
  ]

  tags = {
    Name = "example-instance"
  }
}


data "aws_security_group" "existing" {
  id = "sg-0a48adc1c033afb1f"
}