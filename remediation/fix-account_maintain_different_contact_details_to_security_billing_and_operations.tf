# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Create an AWS Organizations organization
resource "aws_organizations_organization" "org" {
  aws_service_access_principals = ["cloudtrail.amazonaws.com", "config.amazonaws.com"]
  enabled_policy_types         = ["SERVICE_CONTROL_POLICY"]
}

# Create an AWS Organizations account for the Security contact
resource "aws_organizations_account" "security_contact" {
  name  = "Security Contact"
  email = "security-contact@example.com"
  parent_id = aws_organizations_organization.org.roots[0].id
}

# Create an AWS Organizations account for the Billing contact
resource "aws_organizations_account" "billing_contact" {
  name  = "Billing Contact"
  email = "billing-contact@example.com"
  parent_id = aws_organizations_organization.org.roots[0].id
}

# Create an AWS Organizations account for the Operations contact
resource "aws_organizations_account" "operations_contact" {
  name  = "Operations Contact"
  email = "operations-contact@example.com"
  parent_id = aws_organizations_organization.org.roots[0].id
}


This Terraform code creates an AWS Organizations organization and three separate AWS Organizations accounts for the Security, Billing, and Operations contacts. This ensures that the account has distinct, monitored contacts for these different functions, as recommended in the security finding.