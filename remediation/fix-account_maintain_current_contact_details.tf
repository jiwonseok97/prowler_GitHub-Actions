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
resource "aws_iam_policy" "contact_information_policy" {
  name        = "contact-information-policy"
  description = "Allows access to contact information with least privilege"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "iam:GetAccountSummary",
        "iam:GetContactInformation"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Deny",
      "Action": [
        "iam:UpdateAccountPasswordPolicy",
        "iam:UpdateAccountSettings",
        "iam:UpdateContactInformation"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

# Attach the contact information policy to the account contacts group
resource "aws_iam_group_policy_attachment" "contact_information_policy_attachment" {
  group      = aws_iam_group.account_contacts.name
  policy_arn = aws_iam_policy.contact_information_policy.arn
}


This Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Creates an IAM user group called `account-contacts`.
3. Creates two IAM users, `primary-contact` and `alternate-contact`, and adds them to the `account-contacts` group.
4. Creates an IAM policy called `contact-information-policy` that allows the `account-contacts` group to view account contact information, but denies the ability to update the contact information.
5. Attaches the `contact-information-policy` to the `account-contacts` group.

This setup ensures that the primary and alternate contacts have the necessary access to view the account contact information, but with least privilege to prevent unauthorized modifications.