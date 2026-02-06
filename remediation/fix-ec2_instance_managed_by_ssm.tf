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
  assume_role_policy = data.aws_iam_policy_document.instance_role_assume_policy.json
}

data "aws_iam_policy_document" "instance_role_assume_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "instance_role_policy_attachment" {
  role       = aws_iam_role.instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Ensure connectivity to SSM endpoints
resource "aws_vpc_endpoint" "ssm_endpoint" {
  vpc_id            = data.aws_instance.instance.vpc_id
  service_name      = "com.amazonaws.ap-northeast-2.ssm"
  vpc_endpoint_type = "Interface"
}

resource "aws_vpc_endpoint_security_group_association" "ssm_endpoint_security_group" {
  vpc_endpoint_id   = aws_vpc_endpoint.ssm_endpoint.id
  security_group_id = data.aws_instance.instance.vpc_security_group_ids[0]
}