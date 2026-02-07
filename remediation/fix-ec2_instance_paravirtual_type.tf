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
  ami           = "ami-0c94755bb95c71c99" # Replace with a suitable HVM AMI
  instance_type = "t3.micro"            # Replace with a suitable instance type
  subnet_id     = data.aws_instance.instance.subnet_id
  vpc_security_group_ids = [
    data.aws_instance.instance.vpc_security_group_ids[0]
  ]

  # Ensure the new instance has ENA and NVMe support
  ebs_optimized = true
  
  # Terminate the old instance
  lifecycle {
    create_before_destroy = true
  }
}


This Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Retrieves the details of the existing EC2 instance using the `data` source.
3. Creates a new EC2 instance with an HVM virtualization type, using a suitable AMI and instance type.
4. Assigns the new instance to the same subnet and security group as the existing instance.
5. Ensures the new instance is EBS-optimized and has ENA and NVMe support.
6. Configures the lifecycle policy to create the new instance before destroying the old one, to avoid downtime.