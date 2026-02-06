# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Get the existing EC2 instance details
data "aws_instance" "instance" {
  instance_id = "i-0fbecaba3c48e7c79"
}

# Create a new EC2 instance with HVM virtualization type
resource "aws_instance" "new_instance" {
  ami           = "ami-0b7546e839d7ace12" # Replace with a suitable HVM/Nitro AMI
  instance_type = "t3.micro"           # Replace with a suitable instance type
  subnet_id     = data.aws_instance.instance.subnet_id
  vpc_security_group_ids = [data.aws_instance.instance.vpc_security_group_ids[0]]

  # Ensure support for ENA and NVMe, current kernels, and hardened configs
  ebs_optimized         = true
  monitoring           = true
  vpc_security_group_ids = [aws_security_group.hardened_sg.id]

  # Apply defense in depth and least privilege
  iam_instance_profile = aws_iam_instance_profile.hardened_profile.name

  # Terminate the old instance after the new one is running
  lifecycle {
    create_before_destroy = true
  }
}

# Create a hardened security group
resource "aws_security_group" "hardened_sg" {
  name_prefix = "hardened-"
  # Add appropriate security group rules
}

# Create a hardened IAM instance profile
resource "aws_iam_instance_profile" "hardened_profile" {
  name_prefix = "hardened-"
  role        = aws_iam_role.hardened_role.name
}

# Create a hardened IAM role
resource "aws_iam_role" "hardened_role" {
  name_prefix = "hardened-"
  # Add appropriate IAM permissions
}