# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Create an AWS Organizations Organization
resource "aws_organizations_organization" "org" {
  aws_service_access_principals = ["cloudtrail.amazonaws.com", "config.amazonaws.com"]
  enabled_policy_types          = ["SERVICE_CONTROL_POLICY"]
}

# Create an AWS Organizations Account for Security Contacts
resource "aws_organizations_account" "security_account" {
  name  = "Security Contacts"
  email = "security-contacts@example.com"
  parent_id = aws_organizations_organization.org.roots[0].id
}

# Create an AWS Organizations Account for Billing Contacts
resource "aws_organizations_account" "billing_account" {
  name  = "Billing Contacts"
  email = "billing-contacts@example.com"
  parent_id = aws_organizations_organization.org.roots[0].id
}

# Create an AWS Organizations Account for Operations Contacts
resource "aws_organizations_account" "operations_account" {
  name  = "Operations Contacts"
  email = "operations-contacts@example.com"
  parent_id = aws_organizations_organization.org.roots[0].id
}

# Create IAM Users for Security, Billing, and Operations Contacts
resource "aws_iam_user" "security_contact" {
  name = "security-contact"
  account_id = aws_organizations_account.security_account.id
}

resource "aws_iam_user" "billing_contact" {
  name = "billing-contact"
  account_id = aws_organizations_account.billing_account.id
}

resource "aws_iam_user" "operations_contact" {
  name = "operations-contact"
  account_id = aws_organizations_account.operations_account.id
}


This Terraform code creates an AWS Organizations Organization, three separate AWS Organizations Accounts for Security, Billing, and Operations contacts, and three IAM Users for the respective contacts. This ensures that the AWS account has distinct Security, Billing, and Operations contact details, different from each other and from the root contact, as recommended in the security finding.