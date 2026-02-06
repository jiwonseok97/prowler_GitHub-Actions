# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Get the existing EC2 instance details
data "aws_instance" "outdated_instance" {
  instance_id = "i-0fbecaba3c48e7c79"
}

# Create a new launch template with the latest AMI
resource "aws_launch_template" "updated_template" {
  name = "updated-template"
  image_id = data.aws_ami.latest_ami.id
  instance_type = data.aws_instance.outdated_instance.instance_type
  vpc_security_group_ids = [data.aws_instance.outdated_instance.vpc_security_group_ids[0]]
  subnet_id = data.aws_instance.outdated_instance.subnet_id
}

# Get the latest non-deprecated AMI
data "aws_ami" "latest_ami" {
  most_recent = true
  owners      = ["amazon"]
  
  # Filter to exclude deprecated AMIs
  name_regex = "^amzn2-ami-hvm-.*-x86_64-gp2$"
}

# Terminate the existing instance and launch a new one with the updated template
resource "aws_instance" "updated_instance" {
  launch_template {
    id      = aws_launch_template.updated_template.id
    version = "$Latest"
  }
  
  # Ensure the new instance is launched before the old one is terminated
  lifecycle {
    create_before_destroy = true
  }
}

# Terminate the old instance after the new one is running
resource "aws_instance" "old_instance" {
  instance_id = data.aws_instance.outdated_instance.id
  
  # Ensure the old instance is terminated after the new one is running
  lifecycle {
    create_before_destroy = true
  }
  
  # Trigger the termination of the old instance
  depends_on = [aws_instance.updated_instance]
}


This Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Retrieves the details of the existing EC2 instance with the outdated AMI using the `data` source.
3. Creates a new launch template with the latest non-deprecated AMI, using the same instance type and subnet as the existing instance.
4. Retrieves the latest non-deprecated AMI using the `data` source.
5. Launches a new EC2 instance using the updated launch template, ensuring the new instance is created before the old one is terminated.
6. Terminates the old EC2 instance after the new instance is running, using the `create_before_destroy` lifecycle policy.