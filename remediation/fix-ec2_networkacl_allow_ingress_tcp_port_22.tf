# Modify the existing Network ACL to restrict SSH access
resource "aws_network_acl" "remediation_network_acl" {
  vpc_id     = data.aws_vpc.main.id
  subnet_ids = [data.aws_subnet.main.id]
  
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    rule_no     = 100
    action      = "deny"
    cidr_block  = "0.0.0.0/0"
  }

  tags = {
    Name = "Remediation: Restrict SSH access"
  }
}

# Use a bastion host or Session Manager for secure SSH access
resource "aws_security_group" "remediation_bastion_sg" {
  name        = "Remediation: Bastion Host Security Group"
  vpc_id      = data.aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "remediation_bastion_host" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
  subnet_id     = data.aws_subnet.main.id
  vpc_security_group_ids = [aws_security_group.remediation_bastion_sg.id]

  iam_instance_profile = aws_iam_instance_profile.remediation_ssm_profile.name

  tags = {
    Name = "Remediation: Bastion Host"
  }
}

resource "aws_iam_role" "remediation_ssm_role" {
  name = "Remediation-SSM-Role"

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

resource "aws_iam_role_policy_attachment" "remediation_ssm_managed_instance_core" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.remediation_ssm_role.name
}

resource "aws_iam_instance_profile" "remediation_ssm_profile" {
  name = "Remediation-SSM-Profile"
  role = aws_iam_role.remediation_ssm_role.name
}

data "aws_vpc" "main" {
  id = "vpc-0572e1ab82993bb20"
}

data "aws_subnet" "main" {
  id = "subnet-0572e1ab82993bb20"
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}