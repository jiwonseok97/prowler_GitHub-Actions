# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Create an AWS Organizations organization
resource "aws_organizations_organization" "org" {
  aws_service_access_principals = ["cloudtrail.amazonaws.com", "config.amazonaws.com"]
  enabled_policy_types         = ["SERVICE_CONTROL_POLICY"]
}

# Create an AWS Organizations account for Security contacts
resource "aws_organizations_account" "security_account" {
  name  = "Security Contacts"
  email = "security-contacts@example.com"
  parent_id = aws_organizations_organization.org.roots[0].id
}

# Create an AWS Organizations account for Billing contacts
resource "aws_organizations_account" "billing_account" {
  name  = "Billing Contacts"
  email = "billing-contacts@example.com"
  parent_id = aws_organizations_organization.org.roots[0].id
}

# Create an AWS Organizations account for Operations contacts
resource "aws_organizations_account" "operations_account" {
  name  = "Operations Contacts"
  email = "operations-contacts@example.com"
  parent_id = aws_organizations_organization.org.roots[0].id
}

# Create an AWS IAM user for the Security contacts
resource "aws_iam_user" "security_user" {
  name = "security-contacts"
  account_id = aws_organizations_account.security_account.id
}

# Create an AWS IAM user for the Billing contacts
resource "aws_iam_user" "billing_user" {
  name = "billing-contacts"
  account_id = aws_organizations_account.billing_account.id
}

# Create an AWS IAM user for the Operations contacts
resource "aws_iam_user" "operations_user" {
  name = "operations-contacts"
  account_id = aws_organizations_account.operations_account.id
}


The provided Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Creates an AWS Organizations organization with the necessary service access principals and enabled policy types.
3. Creates three separate AWS Organizations accounts for Security, Billing, and Operations contacts, respectively.
4. Creates three AWS IAM users, one for each of the Security, Billing, and Operations contacts, and associates them with the corresponding AWS Organizations accounts.

This setup ensures that the Security, Billing, and Operations contact details are maintained separately, as recommended in the security finding.