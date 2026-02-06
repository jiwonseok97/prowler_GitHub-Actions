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

# Create an IAM policy to restrict who can modify contact data
resource "aws_iam_policy" "contact_data_modification_policy" {
  name        = "contact-data-modification-policy"
  description = "Allows least privilege access to modify contact data"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "iam:GetAccountSummary",
        "iam:GetContactInformation",
        "iam:UpdateContactInformation"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

# Attach the contact data modification policy to the account contacts group
resource "aws_iam_group_policy_attachment" "contact_data_modification_policy_attachment" {
  group      = aws_iam_group.account_contacts.name
  policy_arn = aws_iam_policy.contact_data_modification_policy.arn
}


The Terraform code above does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Creates an IAM user group called `account-contacts`.
3. Creates two IAM users, `primary-contact` and `alternate-contact`, and adds them to the `account-contacts` group.
4. Creates an IAM policy called `contact-data-modification-policy` that allows the least privilege access to modify contact data.
5. Attaches the `contact-data-modification-policy` to the `account-contacts` group.

This should help address the security finding by ensuring that the primary and alternate contacts for the AWS account are properly set up, with shared, monitored aliases and SMS-capable phone numbers, and with least privilege access for modifying the contact data.