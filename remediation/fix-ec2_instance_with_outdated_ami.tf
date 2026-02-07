# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Get the existing EC2 instance details
data "aws_instance" "outdated_instance" {
  instance_id = "i-0fbecaba3c48e7c79"
}

# Create a new EC2 instance with the latest, non-deprecated AMI
resource "aws_instance" "new_instance" {
  ami           = data.aws_ami.latest_ami.id
  instance_type = data.aws_instance.outdated_instance.instance_type
  subnet_id     = data.aws_instance.outdated_instance.subnet_id
  vpc_security_group_ids = data.aws_instance.outdated_instance.vpc_security_group_ids

  tags = {
    Name = "Updated Instance"
  }
}

# Get the latest, non-deprecated AMI
data "aws_ami" "latest_ami" {
  most_recent = true
  owners      = ["amazon"]

  # Filter to exclude deprecated AMIs
  name_regex = "^amzn2-ami-hvm-.*-x86_64-gp2$"
}


This Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Retrieves the existing EC2 instance details using the `data` source `aws_instance`.
3. Creates a new EC2 instance using the `aws_instance` resource, with the latest, non-deprecated AMI obtained from the `data` source `aws_ami`.
4. The new instance is created with the same instance type, subnet, and security groups as the existing instance.
5. The new instance is tagged with the name "Updated Instance".

The key steps are:
- Identifying the existing instance using the provided resource UID.
- Fetching the latest, non-deprecated AMI using the `aws_ami` data source and a name regex filter.
- Creating a new instance with the latest AMI, while preserving the existing instance configuration.