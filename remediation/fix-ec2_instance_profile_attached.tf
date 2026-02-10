# Create an IAM role with the required permissions
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

# Attach the required managed policies to the IAM role
resource "aws_iam_role_policy_attachment" "remediation_instance_role_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.remediation_instance_role.name
}

# Create an IAM instance profile and associate it with the IAM role
resource "aws_iam_instance_profile" "remediation_instance_profile" {
  name = "remediation-instance-profile"
  role = aws_iam_role.remediation_instance_role.name
}

# Associate the IAM instance profile with the existing EC2 instance
data "aws_instance" "existing_instance" {
  instance_id = "i-0fbecaba3c48e7c79"
}

resource "aws_instance" "remediation_instance" {
  instance_type = data.aws_instance.existing_instance.instance_type
  ami           = data.aws_instance.existing_instance.ami
  iam_instance_profile = aws_iam_instance_profile.remediation_instance_profile.name
}