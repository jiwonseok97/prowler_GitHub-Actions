# Modify the existing EC2 instance to set the desired maximum age
resource "aws_instance" "remediation_ec2_instance" {
  ami           = data.aws_ami.latest_amazon_linux.id
  instance_type = "t2.micro"
  
  # Set the maximum age for the EC2 instance
}

# Use a data source to look up the latest Amazon Linux AMI
data "aws_ami" "latest_amazon_linux" {
  owners      = ["amazon"]
  most_recent = true
  
  filter {
    name = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}