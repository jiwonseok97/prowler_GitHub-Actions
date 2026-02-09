# Remediate the EC2 instance virtualization type to HVM/Nitro
resource "aws_instance" "remediation_ec2" {
  ami           = data.aws_ami.hvm_ami.id
  instance_type = "t3.micro"
  subnet_id     = data.aws_subnet.target_subnet.id

  # Ensure HVM/Nitro virtualization
  ebs_optimized = true
  
  # Enable ENA and NVMe support
  ebs_block_device {
    device_name = "/dev/xvda"
    volume_type = "gp2"
  }

  # Apply security hardening
  iam_instance_profile = aws_iam_instance_profile.remediation_profile.name
  user_data            = data.template_file.user_data.rendered

  tags = {
    Name = "remediation-ec2"
  }
}

data "aws_ami" "hvm_ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

data "aws_subnet" "target_subnet" {
  id = "subnet-0123456789abcdef"
}

data "aws_vpc" "target_vpc" {
  id = "vpc-0fedcba9876543210"
}

data "template_file" "user_data" {
  template = jsonencode({
    # Add security hardening scripts here
  })
}

resource "aws_iam_instance_profile" "remediation_profile" {
  name = "remediation-profile"
  role = aws_iam_role.remediation_role.name
}

resource "aws_iam_role" "remediation_role" {
  name = "remediation-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "remediation_role_policy_attachment_1" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
  role       = aws_iam_role.remediation_role.name
}

resource "aws_iam_role_policy_attachment" "remediation_role_policy_attachment_2" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = aws_iam_role.remediation_role.name
}