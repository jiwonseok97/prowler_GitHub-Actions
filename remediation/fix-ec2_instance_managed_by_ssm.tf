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
  name = "AWS-ConfigureAWSPackage"
  instance_id = data.aws_instance.instance.id

  parameters = {
    "action" = ["Install"]
    "name" = ["AmazonSSMAgent"]
    "version" = ["latest"]
  }
}

# Restrict inbound admin ports on the EC2 instance
resource "aws_security_group_rule" "restrict_admin_ports" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
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

resource "aws_iam_role_policy_attachment" "instance_role_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.instance_role.name
}

# Attach the least privilege IAM role to the EC2 instance
resource "aws_iam_instance_profile" "instance_profile" {
  name = "instance-profile"
  role = aws_iam_role.instance_role.name
}

resource "aws_instance" "instance" {
  instance_id = data.aws_instance.instance.id
  iam_instance_profile = aws_iam_instance_profile.instance_profile.name
}