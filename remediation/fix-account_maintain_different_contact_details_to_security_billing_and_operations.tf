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

# Create an AWS Organizations Service Control Policy to restrict access to the root account
resource "aws_organizations_policy" "root_account_access_policy" {
  name        = "Root Account Access Policy"
  description = "Restricts access to the root account"
  content     = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Deny",
      "Action": [
        "iam:*"
      ],
      "Resource": [
        "arn:aws:iam::*:root"
      ]
    }
  ]
}
POLICY
}

# Attach the Service Control Policy to the root of the organization
resource "aws_organizations_policy_attachment" "root_account_access_policy_attachment" {
  policy_id = aws_organizations_policy.root_account_access_policy.id
  target_id = aws_organizations_organization.org.roots[0].id
}


This Terraform code creates an AWS Organizations organization, three separate AWS Organizations accounts for Security, Billing, and Operations contacts, and a Service Control Policy that restricts access to the root account. The purpose of this code is to maintain distinct, monitored Security, Billing, and Operations alternate contacts that differ from the root contact, as recommended in the security finding.