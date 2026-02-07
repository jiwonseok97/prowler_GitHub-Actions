# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Create an AWS Organizations organization
resource "aws_organizations_organization" "org" {
  aws_service_access_principals = ["cloudtrail.amazonaws.com", "config.amazonaws.com"]
  enabled_policy_types          = ["SERVICE_CONTROL_POLICY"]
}

# Create an AWS Organizations account for Security contacts
resource "aws_organizations_account" "security_account" {
  name  = "Security Contacts"
  email = "security-contacts@example.com"
  role_name = "SecurityContactsRole"
}

# Create an AWS Organizations account for Billing contacts
resource "aws_organizations_account" "billing_account" {
  name  = "Billing Contacts"
  email = "billing-contacts@example.com"
  role_name = "BillingContactsRole"
}

# Create an AWS Organizations account for Operations contacts
resource "aws_organizations_account" "operations_account" {
  name  = "Operations Contacts"
  email = "operations-contacts@example.com"
  role_name = "OperationsContactsRole"
}

# Create an AWS Organizations service control policy to restrict access
resource "aws_organizations_policy" "restricted_access_policy" {
  name        = "Restricted Access Policy"
  description = "Restricts access to sensitive resources"
  content     = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Deny",
      "Action": [
        "iam:*",
        "organizations:*",
        "config:*",
        "cloudtrail:*"
      ],
      "Resource": "*"
    }
  ]
}
POLICY
}

# Attach the service control policy to the organization
resource "aws_organizations_policy_attachment" "restricted_access_policy_attachment" {
  policy_id = aws_organizations_policy.restricted_access_policy.id
  target_id = aws_organizations_organization.org.id
}


This Terraform code creates an AWS Organizations organization, three separate accounts for Security, Billing, and Operations contacts, and a service control policy to restrict access to sensitive resources. The code ensures that the Security, Billing, and Operations contacts are maintained in separate accounts, different from the root account, as recommended in the security finding.