# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Retrieve the existing AWS Organization
data "aws_organizations_organization" "org" {}

# Ensure the AWS account is a member of the AWS Organization
resource "aws_organizations_account" "account" {
  name  = "My AWS Account"
  email = "example@example.com"
}

# Create an Organizational Unit (OU) for better structure and management
resource "aws_organizations_organizational_unit" "example_ou" {
  name = "Example OU"
  parent_id = data.aws_organizations_organization.org.roots[0].id
}

# Apply a Service Control Policy (SCP) to the OU for least privilege
resource "aws_organizations_policy" "example_scp" {
  name = "Example SCP"
  content = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Deny",
      "Action": "*",
      "Resource": "*"
    }
  ]
}
POLICY
}

resource "aws_organizations_policy_attachment" "example_scp_attachment" {
  policy_id = aws_organizations_policy.example_scp.id
  target_id = aws_organizations_organizational_unit.example_ou.id
}


This Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Retrieves the existing AWS Organization using the `aws_organizations_organization` data source.
3. Ensures the AWS account is a member of the AWS Organization using the `aws_organizations_account` resource.
4. Creates an Organizational Unit (OU) named "Example OU" under the root of the AWS Organization.
5. Creates a Service Control Policy (SCP) that denies all actions on all resources.
6. Attaches the SCP to the "Example OU" to enforce the least privilege policy.