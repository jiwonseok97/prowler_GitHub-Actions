# Remediate the EC2 instance to be managed by AWS Systems Manager
resource "aws_instance" "remediation_ec2" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
  subnet_id     = data.aws_subnet.public.id

  # Enroll the instance as a Systems Manager managed node
  iam_instance_profile = aws_iam_instance_profile.remediation_ssm_profile.name
  tags = {
    Name = "Remediation EC2 Instance"
  }
}

# Create an IAM role and instance profile for Systems Manager access
resource "aws_iam_role" "remediation_ssm_role" {
  name = "remediation-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "remediation_ssm_managed_instance_core" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.remediation_ssm_role.name
}

resource "aws_iam_instance_profile" "remediation_ssm_profile" {
  name = "remediation-ssm-profile"
  role = aws_iam_role.remediation_ssm_role.name
}

# Look up the latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Look up the public subnet to launch the EC2 instance in
data "aws_subnet" "public" {
  vpc_id            = data.aws_vpc.default.id
  availability_zone = "ap-northeast-2a"
  tags = {
    Tier = "Public"
  }
}

data "aws_vpc" "default" {
  default = true
}