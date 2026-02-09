# Create a new EC2 instance with HVM virtualization type
resource "aws_instance" "remediation_ec2_instance" {
  ami           = data.aws_ami.latest_hvm_ami.id
  instance_type = "t3.micro"
  key_name      = "my-key-pair"

  vpc_security_group_ids = [aws_security_group.remediation_security_group.id]
  subnet_id              = data.aws_subnet.default_subnet.id

  tags = {
    Name = "Remediation EC2 Instance"
  }
}

# Create a new security group to apply to the EC2 instance
resource "aws_security_group" "remediation_security_group" {
  name_prefix = "remediation-sg-"

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
}

# Look up the latest HVM-based Amazon Machine Image (AMI)
data "aws_ami" "latest_hvm_ami" {
  owners      = ["amazon"]
  most_recent = true
  name_regex  = "^amzn2-ami-hvm-.*-x86_64-gp2$"
}

# Look up the default subnet in the current VPC
data "aws_subnet" "default_subnet" {
  default_for_az = true
}