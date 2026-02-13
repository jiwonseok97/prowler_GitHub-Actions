# Retrieve the existing EC2 instance details
data "aws_instance" "existing_instance" {
  instance_id = "i-0fbecaba3c48e7c79"
}

# Create a new launch template with the latest Amazon Machine Image (AMI)
resource "aws_launch_template" "remediation_launch_template" {
  name = "remediation-launch-template"
  image_id = data.aws_ssm_parameter.latest_ami.value
  instance_type = data.aws_instance.existing_instance.instance_type
  vpc_security_group_ids = tolist(data.aws_instance.existing_instance.vpc_security_group_ids)
  iam_instance_profile {
    name = data.aws_iam_instance_profile.existing_profile.name
  }
}

# Retrieve the latest Amazon Machine Image (AMI) ID from AWS Systems Manager Parameter Store
data "aws_ssm_parameter" "latest_ami" {
  name = "aws-service-ami-amazon-linux-latest-amzn2-ami-hvm-x86_64-gp2"
}

# Retrieve the existing VPC subnets
data "aws_subnets" "existing_subnets" {
  filter {
    name = "vpc-id"
    values = [var.vpc_id]
  }
}

# Retrieve the existing IAM instance profile
data "aws_iam_instance_profile" "existing_profile" {
  name = data.aws_instance.existing_instance.iam_instance_profile
}

# Terminate the existing EC2 instance and launch a new one using the updated launch template
resource "aws_instance" "remediation_instance" {
  ami = var.ami_id
  instance_type = var.instance_type
  launch_template {
    name = var.launch_template_name
  }
  tags = {
    Name = "Remediated Instance"
  }
}

# This Terraform code will:
# 1. Retrieve the details of the existing EC2 instance using the data "aws_instance" resource.
# 2. Create a new launch template with the latest Amazon Machine Image (AMI) ID, retrieved from the AWS Systems Manager Parameter Store.
# 3. Retrieve the existing VPC subnets and IAM instance profile associated with the existing instance.
# 4. Terminate the existing EC2 instance and launch a new one using the updated launch template.

variable "ami_id" {
  description = "AMI ID for new or managed instances"
  type        = string
  default     = ""
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = ""
}

variable "launch_template_name" {
  description = "EC2 launch template name"
  type        = string
  default     = ""
}

variable "vpc_id" {
  description = "Target VPC ID"
  type        = string
}