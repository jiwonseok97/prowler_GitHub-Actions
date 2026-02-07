# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Get information about the existing EC2 instance
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
  owners = ["amazon"]
  name_regex = "^amzn2-ami-hvm-.*-x86_64-gp2$"
  exclude_deprecated = true
}

# Create a new Auto Scaling group with the updated launch template
resource "aws_autoscaling_group" "updated_asg" {
  name = "updated-asg"
  desired_capacity = 1
  max_size = 1
  min_size = 1
  target_group_arns = [data.aws_instance.outdated_instance.arn]
  launch_template {
    id = aws_launch_template.updated_template.id
    version = "$Latest"
  }
}

# Terminate the old EC2 instance
resource "aws_autoscaling_group_termination_policy" "terminate_old_instance" {
  autoscaling_group_name = aws_autoscaling_group.updated_asg.name
  instance_id = data.aws_instance.outdated_instance.id
}


This Terraform code does the following:

1. Configures the AWS provider for the ap-northeast-2 region.
2. Retrieves information about the existing EC2 instance with the outdated AMI using the `data` source.
3. Creates a new launch template with the latest non-deprecated AMI.
4. Retrieves the latest non-deprecated AMI using the `data` source.
5. Creates a new Auto Scaling group with the updated launch template.
6. Terminates the old EC2 instance using the `aws_autoscaling_group_termination_policy` resource.

This should address the security finding by replacing the EC2 instance with a new one using the latest non-deprecated AMI.