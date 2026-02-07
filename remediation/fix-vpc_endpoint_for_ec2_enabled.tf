# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Get the existing VPC details
data "aws_vpc" "existing_vpc" {
  id = "vpc-0565167ce4f7cc871"
}

# Create the VPC endpoint for the EC2 service
resource "aws_vpc_endpoint" "ec2_endpoint" {
  vpc_id            = data.aws_vpc.existing_vpc.id
  service_name      = "com.amazonaws.ap-northeast-2.ec2"
  vpc_endpoint_type = "Interface"
  private_dns_enabled = true

  # Apply a restrictive endpoint policy
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": [
        "ec2:Describe*"
      ],
      "Resource": "*"
    }
  ]
}
POLICY
}


This Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Retrieves the existing VPC details using the `data.aws_vpc` data source.
3. Creates a new VPC endpoint for the EC2 service using the `aws_vpc_endpoint` resource.
   - The VPC endpoint is of type "Interface", which is the recommended type for the EC2 service.
   - The `private_dns_enabled` option is set to `true` to keep calls on the AWS network.
   - A restrictive endpoint policy is applied to the VPC endpoint, allowing only the `ec2:Describe*` actions.