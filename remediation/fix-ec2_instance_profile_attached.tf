# Attach an IAM instance profile to the EC2 instance
resource "aws_iam_instance_profile" "remediation_instance_profile" {
  name = "remediation-instance-profile"
  role = aws_iam_role.remediation_role.name
}

# Create an IAM role with the required permissions
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
      },
    ]
  })
}

# Attach the required IAM policies to the role
resource "aws_iam_role_policy_attachment" "remediation_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
  role       = aws_iam_role.remediation_role.name
}

# Associate the IAM instance profile with the EC2 instance
resource "aws_instance" "remediation_instance" {
  ami           = "ami-0b7546e839d7ace12"
  instance_type = "t2.micro"
  iam_instance_profile = aws_iam_instance_profile.remediation_instance_profile.name

  tags = {
    Name = "Remediation Instance"
  }
}