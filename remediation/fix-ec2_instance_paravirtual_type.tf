# Modify the existing EC2 instance to use an HVM/Nitro-based AMI
resource "aws_instance" "remediation_ec2_instance" {
  ami           = data.aws_ami.hvm_ami.id
  instance_type = "t3.micro"
  subnet_id     = tolist(data.aws_subnets.private_subnets.ids)[0]
  vpc_security_group_ids = tolist(data.aws_security_groups.allowed_security_groups.ids)

  iam_instance_profile = data.aws_iam_instance_profile.existing_profile.name

  tags = {
    Name = "remediation-ec2-instance"
  }
}

# Look up an existing HVM/Nitro-based AMI
data "aws_ami" "hvm_ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name = "name"
    values = ["amzn2-ami-hvm-*"]
  }

  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
}

# Look up the existing private subnets
data "aws_subnets" "private_subnets" {
  filter {
    name = "vpc-id"
    values = [data.aws_vpc.existing_vpc.id]
  }

  filter {
    name = "tag-Tier"
    values = ["private"]
  }
}

# Look up the existing security groups
data "aws_security_groups" "allowed_security_groups" {
  filter {
    name = "vpc-id"
    values = [data.aws_vpc.existing_vpc.id]
  }

  filter {
    name = "group-name"
    values = ["allowed-sg"]
  }
}

# Look up the existing VPC
data "aws_vpc" "existing_vpc" {
  filter {
    name = "tag-Name"
    values = ["my-vpc"]
  }
}

# Look up the existing IAM instance profile
data "aws_iam_instance_profile" "existing_profile" {
  name = "my-instance-profile"
}