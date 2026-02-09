# Create an IAM role for the EC2 instance to access AWS Systems Manager
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
      }
    ]
  })
}

# Attach the AWS managed policy for Systems Manager to the IAM role
resource "aws_iam_role_policy_attachment" "remediation_ssm_role_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
  role       = aws_iam_role.remediation_ssm_role.name
}

# Create an EC2 instance with the IAM role attached
resource "aws_instance" "remediation_ec2_instance" {
  ami           = "ami-0b7546d835a9b8926" # Replace with the desired AMI ID
  instance_type = "t2.micro"
  key_name      = "your-key-pair-name" # Replace with the name of your key pair

  iam_instance_profile = aws_iam_role.remediation_ssm_role.name

  tags = {
    Name = "remediation-ec2-instance"
  }
}