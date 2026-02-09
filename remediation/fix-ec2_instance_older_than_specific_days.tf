# Create a new EC2 instance to replace the old one
resource "aws_instance" "remediation_ec2_instance" {
  ami           = data.aws_ami.latest_amazon_linux.id
  instance_type = "t2.micro"
  tags = {
    Name = "Remediation EC2 Instance"
  }
}

# Lookup the latest Amazon Linux AMI
data "aws_ami" "latest_amazon_linux" {
  owners      = ["amazon"]
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}