# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Create an AWS Organizations Organization
resource "aws_organizations_organization" "org" {
  aws_service_access_principals = ["cloudtrail.amazonaws.com", "config.amazonaws.com"]
  feature_set                   = "ALL"
}

# Create an AWS Organizations Account for Security Contacts
resource "aws_organizations_account" "security_account" {
  name  = "Security Contacts"
  email = "security-contacts@example.com"
}

# Create an AWS Organizations Account for Billing Contacts
resource "aws_organizations_account" "billing_account" {
  name  = "Billing Contacts"
  email = "billing-contacts@example.com"
}

# Create an AWS Organizations Account for Operations Contacts
resource "aws_organizations_account" "operations_account" {
  name  = "Operations Contacts"
  email = "operations-contacts@example.com"
}

# Create IAM Users for Security, Billing, and Operations Contacts
resource "aws_iam_user" "security_contact" {
  name = "security-contact"
}

resource "aws_iam_user" "billing_contact" {
  name = "billing-contact"
}

resource "aws_iam_user" "operations_contact" {
  name = "operations-contact"
}

# Assign the IAM Users to the respective AWS Organizations Accounts
resource "aws_organizations_account_delegation" "security_account_delegation" {
  account_id = aws_organizations_account.security_account.id
  user_arn   = aws_iam_user.security_contact.arn
}

resource "aws_organizations_account_delegation" "billing_account_delegation" {
  account_id = aws_organizations_account.billing_account.id
  user_arn   = aws_iam_user.billing_contact.arn
}

resource "aws_organizations_account_delegation" "operations_account_delegation" {
  account_id = aws_organizations_account.operations_account.id
  user_arn   = aws_iam_user.operations_contact.arn
}


This Terraform code creates an AWS Organizations Organization, three separate AWS Organizations Accounts for Security, Billing, and Operations contacts, and three IAM Users for the respective contacts. The IAM Users are then assigned to the corresponding AWS Organizations Accounts using the `aws_organizations_account_delegation` resource.

This setup ensures that the Security, Billing, and Operations contacts are maintained in separate AWS Organizations Accounts, different from the root contact, as recommended in the security finding.