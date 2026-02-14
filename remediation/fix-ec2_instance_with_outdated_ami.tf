# Update the EC2 instance to use a non-deprecated AMI
resource "aws_instance" "remediation_ec2_instance" {
  ami           = data.aws_ami.latest_non_deprecated.id
  instance_type = "t2.micro"
  subnet_id     = tolist(data.aws_subnets.default.ids)[0]
  vpc_security_group_ids = tolist(data.aws_security_groups.default.ids)

  iam_instance_profile = data.aws_iam_instance_profile.default.name
}

data "aws_ami" "latest_non_deprecated" {
  most_recent = true
  owners      = ["amazon"]

  name_regex = "^amzn2-ami-hvm-.*-x86_64-gp2$"
}

data "aws_subnets" "default" {
  filter {
    name = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_security_groups" "default" {
  filter {
    name = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_iam_instance_profile" "default" {
  name = "default"
}

data "aws_vpc" "default" {
  default = true
}