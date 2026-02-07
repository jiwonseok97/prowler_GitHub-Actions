# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Get the existing EC2 instance details
data "aws_instance" "outdated_instance" {
  instance_id = "i-0fbecaba3c48e7c79"
}

# Create a new EC2 instance using a non-deprecated AMI
resource "aws_instance" "new_instance" {
  ami           = "ami-0b7546d835a9b8926" # Replace with a non-deprecated AMI ID
  instance_type = data.aws_instance.outdated_instance.instance_type
  subnet_id     = data.aws_instance.outdated_instance.subnet_id
  vpc_security_group_ids = data.aws_instance.outdated_instance.vpc_security_group_ids

  tags = {
    Name = "Updated Instance"
  }
}

# Terminate the old EC2 instance
resource "aws_instance" "outdated_instance" {
  instance_id = "i-0fbecaba3c48e7c79"
  state       = "terminated"
}


This Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Retrieves the details of the existing EC2 instance with the ID `i-0fbecaba3c48e7c79` using the `data` source.
3. Creates a new EC2 instance using a non-deprecated AMI, with the same instance type, subnet, and security groups as the existing instance.
4. Terminates the old EC2 instance.

The new instance will be created using a non-deprecated, maintained AMI, addressing the security finding. The old instance will be terminated, ensuring that the deprecated AMI is no longer in use.