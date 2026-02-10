# Modify the existing EC2 instance to use HVM virtualization
resource "aws_instance" "remediation_ec2_instance" {
  ami           = data.aws_ami.latest_hvm_ami.id
  instance_type = "t3.micro"
  subnet_id     = data.aws_subnet.default.id

  tags = {
    Name = "Remediated EC2 Instance"
  }
}

# Look up the latest HVM-based Amazon Linux 2 AMI
data "aws_ami" "latest_hvm_ami" {
  owners      = ["amazon"]
  most_recent = true
  name_regex  = "^amzn2-ami-hvm-.*-x86_64-gp2$"
}

# Look up the default subnet in the current VPC
data "aws_subnet" "default" {
}

# Attach the AmazonSSMManagedInstanceCore IAM policy to the instance profile
resource "aws_iam_role_policy_attachment" "remediation_ssm_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.remediation_instance_role.name
}

# Create an IAM role for the EC2 instance
resource "aws_iam_role" "remediation_instance_role" {
  name = "remediation-instance-role"

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

# Create an IAM instance profile and associate it with the EC2 instance
resource "aws_iam_instance_profile" "remediation_instance_profile" {
  name = "remediation-instance-profile"
  role = aws_iam_role.remediation_instance_role.name
}