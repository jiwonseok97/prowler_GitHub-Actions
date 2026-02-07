# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Get information about the existing EC2 instance
data "aws_instance" "problematic_instance" {
  instance_id = "i-0fbecaba3c48e7c79"
}

# Determine the age of the EC2 instance in days
locals {
  instance_age_in_days = floor((timestamp() - data.aws_instance.problematic_instance.launch_time) / 86400)
}

# Terminate the EC2 instance if it is older than the configured maximum age
resource "aws_instance_termination" "terminate_old_instance" {
  count         = local.instance_age_in_days > 30 ? 1 : 0 # Adjust `max_ec2_instance_age_in_days` as needed
  instance_id   = data.aws_instance.problematic_instance.id
  force_delete = true
}

# Create a new EC2 instance from a hardened, updated AMI
resource "aws_instance" "new_instance" {
  ami           = "ami-0b0af3577fe5e3532" # Replace with a secure, updated AMI
  instance_type = "t2.micro"
  subnet_id     = data.aws_instance.problematic_instance.subnet_id

  tags = {
    Name = "Replacement for i-0fbecaba3c48e7c79"
  }
}