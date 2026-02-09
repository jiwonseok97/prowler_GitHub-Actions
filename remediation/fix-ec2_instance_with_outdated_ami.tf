# Create a new AMI using the latest Amazon Linux 2 image
data "aws_ami" "latest_amazon_linux2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Create a new EC2 instance using the latest Amazon Linux 2 AMI
resource "aws_instance" "remediation_ec2_instance" {
  ami           = data.aws_ami.latest_amazon_linux2.id
  instance_type = "t2.micro"
  subnet_id     = "subnet-0123456789abcdef"

  tags = {
    Name = "Remediation EC2 Instance"
  }
}

# Create a new launch template using the latest Amazon Linux 2 AMI
resource "aws_launch_template" "remediation_launch_template" {
  name                   = "remediation-launch-template"
  image_id               = data.aws_ami.latest_amazon_linux2.id
  instance_type          = "t2.micro"
  vpc_security_group_ids = ["sg-0123456789abcdef"]
}

# Create a new auto scaling group using the new launch template
resource "aws_autoscaling_group" "remediation_autoscaling_group" {
  name                = "remediation-autoscaling-group"
  desired_capacity    = 1
  max_size            = 3
  min_size            = 1
  target_group_arns   = ["arn:aws:elasticloadbalancing:ap-northeast-2:132410971304:targetgroup/my-tg/0123456789abcdef"]
  launch_template {
    version = "$Latest"
  }
}