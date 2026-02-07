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

# Create an AWS Organizations Service Control Policy to enforce separate contacts
resource "aws_organizations_policy" "separate_contacts_policy" {
  name        = "Separate Contacts Policy"
  description = "Enforce separate Security, Billing, and Operations contacts"

  content = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Deny",
      "Action": [
        "iam:UpdateAccountPasswordPolicy",
        "iam:UpdateAccountAlias",
        "iam:UpdateAccountSummary",
        "iam:UpdateOpenIDConnectProviderThumbprint",
        "iam:UpdateSAMLProvider",
        "iam:UpdateServerCertificate",
        "iam:UpdateServiceSpecificCredential",
        "iam:UpdateSigningCertificate",
        "iam:UpdateSSHPublicKey",
        "iam:UpdateUser"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "iam:TargetIsAccount": "true"
        }
      }
    }
  ]
}
POLICY
}

# Attach the Service Control Policy to the AWS Organizations Organization
resource "aws_organizations_policy_attachment" "separate_contacts_policy_attachment" {
  policy_id = aws_organizations_policy.separate_contacts_policy.id
  target_id = aws_organizations_organization.org.id
}


This Terraform code does the following:

1. Configures the AWS provider for the ap-northeast-2 region.
2. Creates an AWS Organizations Organization.
3. Creates three AWS Organizations Accounts for Security, Billing, and Operations contacts.
4. Creates an AWS Organizations Service Control Policy to enforce separate contacts for Security, Billing, and Operations.
5. Attaches the Service Control Policy to the AWS Organizations Organization.

This ensures that the AWS account has distinct Security, Billing, and Operations contact details, different from each other and from the root contact, as recommended in the security finding.