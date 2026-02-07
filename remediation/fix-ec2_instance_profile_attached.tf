# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Get the existing EC2 instance
data "aws_instance" "instance" {
  instance_id = "i-0fbecaba3c48e7c79"
}

# Create a new IAM instance profile
resource "aws_iam_instance_profile" "instance_profile" {
  name = "my-instance-profile"
  role = aws_iam_role.instance_role.name
}

# Create a new IAM role with the required permissions
resource "aws_iam_role" "instance_role" {
  name = "my-instance-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

# Attach the IAM instance profile to the existing EC2 instance
resource "aws_ec2_instance_profile_attachment" "instance_profile_attachment" {
  instance_id     = data.aws_instance.instance.id
  instance_profile = aws_iam_instance_profile.instance_profile.name
}


This Terraform code does the following:

1. Configures the AWS provider for the ap-northeast-2 region.
2. Retrieves the existing EC2 instance using the `data` source.
3. Creates a new IAM instance profile with the name "my-instance-profile" and associates it with an IAM role.
4. Creates a new IAM role with the name "my-instance-role" and the required assume role policy.
5. Attaches the IAM instance profile to the existing EC2 instance.

This should address the security finding by ensuring that the EC2 instance is associated with an IAM instance profile role, which can be used to grant the instance only the permissions it requires (least privilege).