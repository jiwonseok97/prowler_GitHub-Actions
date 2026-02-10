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

# Attach the AmazonSSMManagedInstanceCore policy to the IAM role
resource "aws_iam_role_policy_attachment" "remediation_ssm_role_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.remediation_ssm_role.name
}

# Create an IAM instance profile and associate it with the EC2 instance
resource "aws_iam_instance_profile" "remediation_ssm_instance_profile" {
  name = "remediation-ssm-instance-profile"
  role = aws_iam_role.remediation_ssm_role.name
}

# Modify the existing EC2 instance to be managed by AWS Systems Manager
data "aws_instance" "existing_ec2_instance" {
}

resource "aws_instance" "remediation_ec2_instance" {
  iam_instance_profile = aws_iam_instance_profile.remediation_ssm_instance_profile.name
  
  # Use the same attributes as the existing instance
  ami           = data.aws_instance.existing_ec2_instance.ami
  instance_type = data.aws_instance.existing_ec2_instance.instance_type
  subnet_id     = data.aws_instance.existing_ec2_instance.subnet_id
  vpc_security_group_ids = data.aws_instance.existing_ec2_instance.vpc_security_group_ids
}