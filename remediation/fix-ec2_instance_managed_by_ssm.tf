# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Get information about the existing EC2 instance
data "aws_instance" "instance" {
  instance_id = "i-0fbecaba3c48e7c79"
}

# Enroll the EC2 instance as a Systems Manager managed node
resource "aws_ssm_association" "instance_association" {
  name = "AWS-RunShellScript"
  targets {
    key    = "instance-id"
    values = [data.aws_instance.instance.id]
  }
  parameters = {
    "commands" = [""]
  }
}

# Restrict inbound admin ports on the EC2 instance
resource "aws_security_group" "instance_security_group" {
  name   = "instance-security-group"
  vpc_id = data.aws_instance.instance.vpc_id

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

# Attach the security group to the EC2 instance
resource "aws_network_interface_sg_attachment" "instance_sg_attachment" {
  security_group_id    = aws_security_group.instance_security_group.id
  network_interface_id = data.aws_instance.instance.primary_network_interface_id
}

# Create an IAM role with the least privilege required for Systems Manager
resource "aws_iam_role" "instance_role" {
  name = "instance-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# Attach the required policies to the IAM role
resource "aws_iam_role_policy_attachment" "instance_role_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.instance_role.name
}

# Attach the IAM role to the EC2 instance
resource "aws_iam_instance_profile" "instance_profile" {
  name = "instance-profile"
  role = aws_iam_role.instance_role.name
}

resource "aws_ec2_instance_profile" "instance_profile_attachment" {
  instance_id = data.aws_instance.instance.id
  iam_instance_profile = aws_iam_instance_profile.instance_profile.name
}


This Terraform code does the following:

1. Configures the AWS provider for the ap-northeast-2 region.
2. Retrieves information about the existing EC2 instance using the `data.aws_instance` data source.
3. Enrolls the EC2 instance as a Systems Manager managed node using the `aws_ssm_association` resource.
4. Restricts inbound admin ports (SSH) on the EC2 instance using the `aws_security_group` and `aws_network_interface_sg_attachment` resources.
5. Creates an IAM role with the least privilege required for Systems Manager using the `aws_iam_role` resource.
6. Attaches the required policies to the IAM role using the `aws_iam_role_policy_attachment` resource.
7. Attaches the IAM role to the EC2 instance using the `aws_iam_instance_profile` and `aws_ec2_instance_profile` resources.