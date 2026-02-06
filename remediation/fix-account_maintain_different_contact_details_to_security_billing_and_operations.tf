# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Create an AWS Organizations organization
resource "aws_organizations_organization" "org" {
  aws_service_access_principals = ["cloudtrail.amazonaws.com", "config.amazonaws.com"]
  feature_set                   = "ALL"
}

# Create an AWS Organizations account for Security contact
resource "aws_organizations_account" "security_contact" {
  name  = "Security Contact"
  email = "security-contact@example.com"
  role_name = "SecurityContactRole"
  parent_id = aws_organizations_organization.org.roots[0].id
}

# Create an AWS Organizations account for Billing contact
resource "aws_organizations_account" "billing_contact" {
  name  = "Billing Contact"
  email = "billing-contact@example.com"
  role_name = "BillingContactRole"
  parent_id = aws_organizations_organization.org.roots[0].id
}

# Create an AWS Organizations account for Operations contact
resource "aws_organizations_account" "operations_contact" {
  name  = "Operations Contact"
  email = "operations-contact@example.com"
  role_name = "OperationsContactRole"
  parent_id = aws_organizations_organization.org.roots[0].id
}


The provided Terraform code creates an AWS Organizations organization and three separate AWS Organizations accounts for the Security, Billing, and Operations contacts. This ensures that the AWS account has distinct, monitored contacts for these different functions, as recommended in the security finding.

The code configures the AWS provider for the ap-northeast-2 region, creates the AWS Organizations organization, and then creates the three separate AWS Organizations accounts for the Security, Billing, and Operations contacts. Each account has a unique name and email address, and a specific role name assigned to it.