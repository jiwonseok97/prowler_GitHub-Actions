# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Create an AWS Organizations organization
resource "aws_organizations_organization" "example" {
  aws_service_access_principals = ["cloudtrail.amazonaws.com", "config.amazonaws.com"]
  enabled_policy_types         = ["SERVICE_CONTROL_POLICY"]
}

# Create an AWS Organizations account for Security contacts
resource "aws_organizations_account" "security" {
  name  = "Security Contacts"
  email = "security-contacts@example.com"
  parent_id = aws_organizations_organization.example.roots[0].id
}

# Create an AWS Organizations account for Billing contacts
resource "aws_organizations_account" "billing" {
  name  = "Billing Contacts"
  email = "billing-contacts@example.com"
  parent_id = aws_organizations_organization.example.roots[0].id
}

# Create an AWS Organizations account for Operations contacts
resource "aws_organizations_account" "operations" {
  name  = "Operations Contacts"
  email = "operations-contacts@example.com"
  parent_id = aws_organizations_organization.example.roots[0].id
}

# Create an AWS IAM user for the Security contacts
resource "aws_iam_user" "security_contacts" {
  name = "security-contacts"
  force_destroy = true
}

# Create an AWS IAM user for the Billing contacts
resource "aws_iam_user" "billing_contacts" {
  name = "billing-contacts"
  force_destroy = true
}

# Create an AWS IAM user for the Operations contacts
resource "aws_iam_user" "operations_contacts" {
  name = "operations-contacts"
  force_destroy = true
}


This Terraform code creates an AWS Organizations organization, three separate AWS Organizations accounts for Security, Billing, and Operations contacts, and three IAM users for the respective contact details. This ensures that the AWS account has distinct, monitored Security, Billing, and Operations alternate contacts that differ from the root contact, as recommended in the security finding.