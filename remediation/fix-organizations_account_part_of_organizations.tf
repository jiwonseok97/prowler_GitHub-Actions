# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Retrieve the existing AWS Organization
data "aws_organizations_organization" "org" {}

# Create a new Organizational Unit (OU) for the account
resource "aws_organizations_organizational_unit" "example_ou" {
  name      = "Example OU"
  parent_id = data.aws_organizations_organization.org.roots[0].id
}

# Move the account to the new OU
resource "aws_organizations_account" "example_account" {
  name  = "Example Account"
  email = "example@example.com"
  parent_id = aws_organizations_organizational_unit.example_ou.id
}

# Create a Service Control Policy (SCP) to enforce least privilege
resource "aws_organizations_policy" "least_privilege_scp" {
  name        = "Least Privilege SCP"
  description = "Enforces least privilege access"
  content     = <<POLICY
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

# Attach the SCP to the OU
resource "aws_organizations_policy_attachment" "least_privilege_scp_attachment" {
  policy_id = aws_organizations_policy.least_privilege_scp.id
  target_id = aws_organizations_organizational_unit.example_ou.id
}


This Terraform code does the following:

1. Configures the AWS provider for the ap-northeast-2 region.
2. Retrieves the existing AWS Organization using a data source.
3. Creates a new Organizational Unit (OU) named "Example OU" under the root of the organization.
4. Moves the account to the new OU.
5. Creates a Service Control Policy (SCP) that denies all actions, effectively enforcing least privilege access.
6. Attaches the SCP to the "Example OU".