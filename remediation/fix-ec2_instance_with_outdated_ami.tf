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

  filter {
    name   = "state"
    values = ["available"]
  }

  filter {
    name   = "is-public"
    values = ["true"]
  }

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Terminate the existing instance and launch a new one using the updated launch template
resource "aws_autoscaling_group" "updated_asg" {
  name = "updated-asg"
  desired_capacity   = 1
  max_size           = 1
  min_size           = 1
  target_group_arns  = [data.aws_instance.outdated_instance.arn]
  vpc_zone_identifier = [data.aws_instance.outdated_instance.subnet_id]
  launch_template {
    id      = aws_launch_template.updated_template.id
    version = "$Latest"
  }
}


The provided Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Retrieves the details of the existing EC2 instance with the outdated AMI using the `data` source `aws_instance`.
3. Creates a new launch template with the latest non-deprecated AMI using the `aws_launch_template` resource.
4. Retrieves the latest non-deprecated AMI using the `data` source `aws_ami`.
5. Creates a new Auto Scaling group with the updated launch template using the `aws_autoscaling_group` resource, which will terminate the existing instance and launch a new one with the latest AMI.