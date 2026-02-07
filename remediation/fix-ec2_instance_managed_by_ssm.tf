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
  name = "AmazonSSMAssociationDefault"
  instance_id = data.aws_instance.instance.id
}

# Restrict inbound admin ports on the instance's security group
resource "aws_security_group_rule" "restrict_admin_ports" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = data.aws_instance.instance.vpc_security_group_ids[0]
}

# Create an IAM role with the least privilege required for Systems Manager
resource "aws_iam_role" "ssm_role" {
  name = "ssm-role"

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
resource "aws_iam_role_policy_attachment" "ssm_role_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.ssm_role.name
}

# Attach the IAM role to the EC2 instance
resource "aws_iam_instance_profile" "ssm_instance_profile" {
  name = "ssm-instance-profile"
  role = aws_iam_role.ssm_role.name
}

resource "aws_ec2_instance_profile" "instance_profile" {
  instance_id = data.aws_instance.instance.id
  iam_instance_profile = aws_iam_instance_profile.ssm_instance_profile.name
}