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
  name        = "Example SCP"
  description = "Enforce least privilege access"
  content     = file("example_scp.json")
}

resource "aws_organizations_policy_attachment" "example_scp_attachment" {
  policy_id = aws_organizations_policy.example_scp.id
  target_id = aws_organizations_organizational_unit.example_ou.id
}