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

# Enable all features for the AWS Organization
resource "aws_organizations_organization" "org" {
  aws_service_access_principals = ["cloudtrail.amazonaws.com", "config.amazonaws.com", "guardduty.amazonaws.com", "ram.amazonaws.com"]
  enabled_policy_types         = ["SERVICE_CONTROL_POLICY", "TAG_POLICY"]

  feature_set = "ALL"
}

# Create a Service Control Policy (SCP) to enforce least privilege
resource "aws_organizations_policy" "least_privilege_scp" {
  name        = "Least Privilege SCP"
  description = "Enforces least privilege access for all accounts in the organization"
  type        = "SERVICE_CONTROL_POLICY"

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

# Attach the Least Privilege SCP to the root of the AWS Organization
resource "aws_organizations_policy_attachment" "least_privilege_scp_attachment" {
  policy_id = aws_organizations_policy.least_privilege_scp.id
  target_id = data.aws_organizations_organization.org.roots[0].id
}


This Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Retrieves the existing AWS Organization using a data source.
3. Ensures the AWS account is a member of the AWS Organization using the `aws_organizations_account` resource.
4. Enables all features for the AWS Organization using the `aws_organizations_organization` resource.
5. Creates a Service Control Policy (SCP) to enforce least privilege access for all accounts in the organization.
6. Attaches the Least Privilege SCP to the root of the AWS Organization.