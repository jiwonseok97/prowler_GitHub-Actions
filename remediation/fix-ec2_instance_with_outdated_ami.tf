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
  owners = ["amazon"]
  name_regex = "^amzn2-ami-hvm-.*"
  exclude_deprecated = true
}

# Terminate the existing instance and launch a new one with the updated template
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
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }
}


This Terraform code does the following:

1. Configures the AWS provider for the ap-northeast-2 region.
2. Retrieves the details of the existing EC2 instance with the outdated AMI using the `data` source.
3. Creates a new launch template with the latest non-deprecated AMI, using the same instance type, VPC security group, and subnet as the existing instance.
4. Retrieves the latest non-deprecated AMI using the `data` source.
5. Creates a new Auto Scaling group (ASG) with the updated launch template, targeting the existing instance. This will terminate the existing instance and launch a new one with the latest AMI, using a rolling update strategy to maintain availability.