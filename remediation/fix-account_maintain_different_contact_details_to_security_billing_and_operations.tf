# Configure the AWS provider for the ap-northeast-2 region

# Create an AWS Organizations organization
resource "aws_organizations_organization" "org" {
  aws_service_access_principals = ["cloudtrail.amazonaws.com", "config.amazonaws.com"]
  feature_set                   = "ALL"
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

# Create IAM users for Security, Billing, and Operations contacts
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


# This Terraform code creates an AWS Organizations organization, three separate AWS Organizations accounts for Security, Billing, and Operations contacts, and IAM users for each of these contacts. This ensures that the security, billing, and operations contacts are maintained separately and are different from the root contact, as recommended in the security finding.