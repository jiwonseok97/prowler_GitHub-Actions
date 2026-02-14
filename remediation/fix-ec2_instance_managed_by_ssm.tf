# Enroll the EC2 instance as a Systems Manager managed node
resource "aws_ssm_activation" "remediation_ssm_activation" {
  iam_role = var.ssm_iam_role
  name = "remediation-ssm-activation"
  description        = "Activate EC2 instance for AWS Systems Manager"
  registration_limit = 1
  tags = {
    Name = "remediation-ssm-activation"
  }
}

# Attach the AmazonSSMManagedInstanceCore policy to the instance profile

# Ensure the EC2 instance has the required IAM instance profile
data "aws_iam_instance_profile" "existing_instance_profile" {
  name = "my-instance-profile"
}

# Update the EC2 instance to use the IAM instance profile
resource "aws_instance" "remediation_ec2_instance" {
  instance_type = var.instance_type
  ami           = data.aws_ami.amazon_linux.id
  iam_instance_profile = data.aws_iam_instance_profile.existing_instance_profile.name

  vpc_security_group_ids = tolist(data.aws_instance.existing_instance.vpc_security_group_ids)
  subnet_id              = data.aws_instance.existing_instance.subnet_id

  tags = {
    Name = "remediation-ec2-instance"
  }
}

# Look up the existing EC2 instance
data "aws_instance" "existing_instance" {
  instance_id = "i-0fbecaba3c48e7c79"
}

# Look up the Amazon Linux 2 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

variable "ssm_iam_role" {
  description = "IAM role for SSM activation"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = ""
}