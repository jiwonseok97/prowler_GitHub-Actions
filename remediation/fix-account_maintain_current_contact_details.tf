# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Create an IAM user group for account contacts
resource "aws_iam_group" "account_contacts" {
  name = "account-contacts"
}

# Create IAM users for the primary and alternate contacts
resource "aws_iam_user" "primary_contact" {
  name = "primary-contact"
}

resource "aws_iam_user" "alternate_contact" {
  name = "alternate-contact"
}

# Add the IAM users to the account contacts group
resource "aws_iam_group_membership" "account_contacts_membership" {
  name = "account-contacts-membership"
  group = aws_iam_group.account_contacts.name
  users = [
    aws_iam_user.primary_contact.name,
    aws_iam_user.alternate_contact.name
  ]
}

# Create an IAM policy to restrict access to contact information
data "aws_iam_policy_document" "contact_information_policy" {
  statement {
    effect = "Allow"
    actions = [
      "iam:GetAccountSummary",
      "iam:GetContactInformation"
    ]
    resources = ["*"]
  }
  statement {
    effect = "Deny"
    actions = [
      "iam:UpdateAccountPasswordPolicy",
      "iam:UpdateAccountSettings",
      "iam:UpdateOpenIDConnectProviderThumbprint",
      "iam:UpdateSAMLProvider",
      "iam:UpdateServiceSpecificCredential",
      "iam:UpdateSigningCertificate",
      "iam:UpdateSSHPublicKey",
      "iam:UpdateUser"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "contact_information_policy" {
  name        = "contact-information-policy"
  description = "Allows read-only access to account contact information"
  policy      = data.aws_iam_policy_document.contact_information_policy.json
}

# Attach the contact information policy to the account contacts group
resource "aws_iam_group_policy_attachment" "account_contacts_policy_attachment" {
  group      = aws_iam_group.account_contacts.name
  policy_arn = aws_iam_policy.contact_information_policy.arn
}