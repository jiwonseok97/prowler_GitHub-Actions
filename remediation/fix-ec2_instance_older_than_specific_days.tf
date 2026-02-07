# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Get information about the existing EC2 instance
data "aws_instance" "old_instance" {
  instance_id = "i-0fbecaba3c48e7c79"
}

# Determine the age of the EC2 instance in days
locals {
  instance_age_in_days = floor((timestamp() - data.aws_instance.old_instance.launch_time) / 86400)
}

# Terminate the old EC2 instance
resource "aws_instance" "new_instance" {
  ami           = data.aws_instance.old_instance.ami
  instance_type = data.aws_instance.old_instance.instance_type
  subnet_id     = data.aws_instance.old_instance.subnet_id
  vpc_security_group_ids = data.aws_instance.old_instance.vpc_security_group_ids

  # Ensure the new instance is created before the old one is terminated
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_instance" "old_instance" {
  # Terminate the old instance if it is older than the configured maximum age
  count = local.instance_age_in_days > 30 ? 1 : 0
  instance_id = data.aws_instance.old_instance.id

  # Force the termination of the old instance
  force_delete = true
}