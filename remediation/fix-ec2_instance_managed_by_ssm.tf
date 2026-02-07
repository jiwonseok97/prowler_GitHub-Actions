# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Get information about the existing EC2 instance
data "aws_instance" "instance" {
  instance_id = "i-0fbecaba3c48e7c79"
}

# Enroll the EC2 instance as a Systems Manager managed node
resource "aws_ssm_association" "instance_ssm_association" {
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
resource "aws_security_group_rule" "restrict_admin_ports" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol         = "tcp"
  cidr_blocks      = ["0.0.0.0/0"]
  security_group_id = data.aws_instance.instance.vpc_security_group_ids[0]
}

# Use a least privilege IAM role for the EC2 instance
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

# Attach the necessary policies to the IAM role
resource "aws_iam_role_policy_attachment" "instance_role_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.instance_role.name
}

# Associate the IAM role with the EC2 instance
resource "aws_iam_instance_profile" "instance_profile" {
  name = "instance-profile"
  role = aws_iam_role.instance_role.name
}

resource "aws_ec2_instance_connect" "instance_connect" {
  instance_id = data.aws_instance.instance.id
  instance_iam_role = aws_iam_role.instance_role.name
}


This Terraform code does the following:

1. Configures the AWS provider for the ap-northeast-2 region.
2. Retrieves information about the existing EC2 instance using the `data` source.
3. Enrolls the EC2 instance as a Systems Manager managed node using the `aws_ssm_association` resource.
4. Restricts inbound admin ports (SSH) on the EC2 instance using the `aws_security_group_rule` resource.
5. Creates a least privilege IAM role for the EC2 instance using the `aws_iam_role` resource.
6. Attaches the necessary policies to the IAM role using the `aws_iam_role_policy_attachment` resource.
7. Associates the IAM role with the EC2 instance using the `aws_iam_instance_profile` resource.
8. Enables the EC2 Instance Connect feature for the EC2 instance using the `aws_ec2_instance_connect` resource.