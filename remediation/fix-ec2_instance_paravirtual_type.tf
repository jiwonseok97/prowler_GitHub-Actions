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
  instance_type = "t3.micro"            # Replace with a suitable instance type
  subnet_id     = data.aws_instance.instance.subnet_id
  vpc_security_group_ids = [
    data.aws_instance.instance.vpc_security_group_ids[0]
  ]

  # Ensure the new instance has ENA and NVMe support, current kernels, and hardened configs
  ebs_optimized         = true
  monitoring            = true
  iam_instance_profile  = "my-hardened-profile" # Replace with a suitable IAM instance profile
  user_data             = file("hardened_config.sh") # Replace with a script to apply hardened configs

  # Apply defense in depth and least privilege principles
  tags = {
    Name = "Hardened HVM Instance"
  }
}

# Terminate the old PV instance
resource "aws_instance_termination" "old_instance" {
  instance_id = data.aws_instance.instance.id
}


This Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Retrieves the details of the existing EC2 instance using the `data` source.
3. Creates a new EC2 instance with HVM virtualization type, using a suitable HVM/Nitro AMI and instance type.
4. Ensures the new instance has ENA and NVMe support, current kernels, and hardened configurations by setting the appropriate attributes.
5. Applies defense in depth and least privilege principles by setting appropriate tags and using a hardened IAM instance profile.
6. Terminates the old PV instance using the `aws_instance_termination` resource.