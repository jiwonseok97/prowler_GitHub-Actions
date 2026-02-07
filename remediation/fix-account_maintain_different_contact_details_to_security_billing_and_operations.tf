# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Create an AWS Organizations organization
resource "aws_organizations_organization" "org" {
  aws_service_access_principals = ["cloudtrail.amazonaws.com", "config.amazonaws.com", "guardduty.amazonaws.com", "securityhub.amazonaws.com"]
  feature_set                   = "ALL"
}

# Create an AWS Organizations account
resource "aws_organizations_account" "account" {
  name  = "My Account"
  email = "admin@example.com"
}

# Create an AWS IAM user for the Security contact
resource "aws_iam_user" "security_contact" {
  name = "security-contact"
}

# Create an AWS IAM user for the Billing contact
resource "aws_iam_user" "billing_contact" {
  name = "billing-contact"
}

# Create an AWS IAM user for the Operations contact
resource "aws_iam_user" "operations_contact" {
  name = "operations-contact"
}

# Create an AWS IAM group for the Security contact
resource "aws_iam_group" "security_group" {
  name = "security-group"
}

# Create an AWS IAM group for the Billing contact
resource "aws_iam_group" "billing_group" {
  name = "billing-group"
}

# Create an AWS IAM group for the Operations contact
resource "aws_iam_group" "operations_group" {
  name = "operations-group"
}

# Add the Security contact user to the Security group
resource "aws_iam_user_group_membership" "security_contact_membership" {
  user_name = aws_iam_user.security_contact.name
  groups    = [aws_iam_group.security_group.name]
}

# Add the Billing contact user to the Billing group
resource "aws_iam_user_group_membership" "billing_contact_membership" {
  user_name = aws_iam_user.billing_contact.name
  groups    = [aws_iam_group.billing_group.name]
}

# Add the Operations contact user to the Operations group
resource "aws_iam_user_group_membership" "operations_contact_membership" {
  user_name = aws_iam_user.operations_contact.name
  groups    = [aws_iam_group.operations_group.name]
}


This Terraform code creates an AWS Organizations organization, an AWS Organizations account, and three IAM users for the Security, Billing, and Operations contacts. It also creates three IAM groups and adds the respective users to the corresponding groups. This ensures that the Security, Billing, and Operations contacts are maintained as distinct, monitored contacts that differ from the root contact, as recommended in the security finding.