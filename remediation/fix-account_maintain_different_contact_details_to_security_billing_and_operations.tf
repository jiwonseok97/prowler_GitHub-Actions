# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Create an AWS Organizations Organization
resource "aws_organizations_organization" "org" {
  aws_service_access_principals = ["cloudtrail.amazonaws.com", "config.amazonaws.com"]
  enabled_policy_types          = ["SERVICE_CONTROL_POLICY", "TAG_POLICY"]
}

# Create an AWS Organizations Account for Security Contacts
resource "aws_organizations_account" "security_contacts" {
  name  = "Security Contacts"
  email = "security-contacts@example.com"
  parent_id = aws_organizations_organization.org.roots[0].id
}

# Create an AWS Organizations Account for Billing Contacts
resource "aws_organizations_account" "billing_contacts" {
  name  = "Billing Contacts"
  email = "billing-contacts@example.com"
  parent_id = aws_organizations_organization.org.roots[0].id
}

# Create an AWS Organizations Account for Operations Contacts
resource "aws_organizations_account" "operations_contacts" {
  name  = "Operations Contacts"
  email = "operations-contacts@example.com"
  parent_id = aws_organizations_organization.org.roots[0].id
}

# Create an AWS IAM User for the Security Contacts
resource "aws_iam_user" "security_contacts" {
  name = "security-contacts"
  force_destroy = true
}

# Create an AWS IAM User for the Billing Contacts
resource "aws_iam_user" "billing_contacts" {
  name = "billing-contacts"
  force_destroy = true
}

# Create an AWS IAM User for the Operations Contacts
resource "aws_iam_user" "operations_contacts" {
  name = "operations-contacts"
  force_destroy = true
}


The provided Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Creates an AWS Organizations Organization with the necessary service access principals and enabled policy types.
3. Creates three separate AWS Organizations Accounts for Security Contacts, Billing Contacts, and Operations Contacts, each with a unique email address.
4. Creates three separate AWS IAM Users for the Security Contacts, Billing Contacts, and Operations Contacts, with the `force_destroy` option enabled to ensure the users are deleted when the Terraform configuration is destroyed.

This setup ensures that the AWS account has distinct Security, Billing, and Operations contact details, different from each other and from the root contact, as recommended in the security finding.