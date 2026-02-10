# Modify the existing network ACL to restrict RDP access
resource "aws_network_acl" "remediation_network_acl" {
  vpc_id     = data.aws_vpc.current.id
  subnet_ids = [for s in data.aws_subnet.all : s.id]
  
  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    rule_no     = 100
    action      = "deny"
    cidr_block  = "0.0.0.0/0"
  }

  tags = {
    Name = "Remediation: Restrict RDP access"
  }
}

# Use a bastion host or Session Manager for remote access
resource "aws_instance" "remediation_bastion_host" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
  subnet_id     = data.aws_subnet.public.id

  vpc_security_group_ids = [
    aws_security_group.remediation_bastion_sg.id
  ]

  iam_instance_profile = aws_iam_instance_profile.remediation_bastion_profile.name

  tags = {
    Name = "Remediation: Bastion Host"
  }
}

resource "aws_security_group" "remediation_bastion_sg" {
  name   = "Remediation: Bastion Host SG"
  vpc_id = data.aws_vpc.current.id

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

resource "aws_iam_instance_profile" "remediation_bastion_profile" {
  name = "remediation-bastion-profile"
  role = aws_iam_role.remediation_bastion_role.name
}

resource "aws_iam_role" "remediation_bastion_role" {
  name = "remediation-bastion-role"

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

resource "aws_iam_role_policy_attachment" "remediation_bastion_ssm_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.remediation_bastion_role.name
}

data "aws_vpc" "current" {
  id = "vpc-0123456789abcdef"
}

data "aws_subnet" "all" {
  vpc_id = data.aws_vpc.current.id
}

data "aws_subnet" "public" {
  vpc_id            = data.aws_vpc.current.id
  availability_zone = "ap-northeast-2a"
  cidr_block        = "10.0.1.0/24"
}

data "aws_ami" "amazon_linux" {
  owners      = ["amazon"]
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}