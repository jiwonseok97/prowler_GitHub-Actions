# Modify the existing EC2 instance to set a new maximum age
resource "aws_instance" "remediation_ec2_instance" {
  ami           = data.aws_ami.latest_amazon_linux.id
  instance_type = "t2.micro"
  subnet_id     = tolist(data.aws_subnets.default.ids)[0]
  vpc_security_group_ids = tolist(data.aws_security_groups.default.ids)

  iam_instance_profile = data.aws_iam_instance_profile.remediation_instance_profile.name

  tags = {
    Name = "remediation-ec2-instance"
  }
}

# Use a data source to look up the existing IAM instance profile
data "aws_iam_instance_profile" "remediation_instance_profile" {
  name = "remediation-instance-profile"
}

# Use a data source to look up the latest Amazon Linux AMI
data "aws_ami" "latest_amazon_linux" {
  owners      = ["amazon"]
  most_recent = true
  name_regex  = "^amzn2-ami-hvm-.*-x86_64-gp2$"
}

# Use data sources to look up the default VPC and security groups
data "aws_subnets" "default" {
  filter {
    name = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_security_groups" "default" {
}

data "aws_vpc" "default" {
  default = true
}

# Use a data source to look up an existing IAM role
data "aws_iam_role" "existing_role" {
  name = "existing-role-name"
}

# Attach the AWS managed policy for SSM to the existing IAM role