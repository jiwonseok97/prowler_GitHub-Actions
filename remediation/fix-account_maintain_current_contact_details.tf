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
  group = aws_iam_group.account_contacts.name
  users = [
    aws_iam_user.primary_contact.name,
    aws_iam_user.alternate_contact.name
  ]
}

# Create IAM policies for the account contact roles
resource "aws_iam_policy" "security_contact_policy" {
  name        = "security-contact-policy"
  description = "Permissions for the security contact"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "iam:GetAccountSummary",
        "iam:GetAccountPasswordPolicy",
        "iam:GetAccountAuthorizationDetails",
        "iam:GetLoginProfile",
        "iam:GetUser",
        "iam:GetUserPolicy",
        "iam:ListUsers",
        "iam:ListUserPolicies",
        "iam:ListAttachedUserPolicies",
        "iam:ListGroupsForUser",
        "iam:ListAccessKeys",
        "iam:ListSSHPublicKeys",
        "iam:ListMFADevices"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "billing_contact_policy" {
  name        = "billing-contact-policy"
  description = "Permissions for the billing contact"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "aws-portal:ViewBilling",
        "aws-portal:ViewPaymentMethods",
        "aws-portal:ModifyPaymentMethods"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "operations_contact_policy" {
  name        = "operations-contact-policy"
  description = "Permissions for the operations contact"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "cloudwatch:GetMetricData",
        "cloudwatch:GetMetricStatistics",
        "cloudwatch:ListMetrics",
        "cloudwatch:PutMetricData",
        "cloudwatch:DescribeAlarms",
        "cloudwatch:PutCompositeAlarm",
        "cloudwatch:PutDashboard",
        "cloudwatch:PutMetricAlarm",
        "cloudwatch:SetAlarmState"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

# Attach the IAM policies to the account contacts group
resource "aws_iam_group_policy_attachment" "security_contact_policy_attachment" {
  group      = aws_iam_group.account_contacts.name
  policy_arn = aws_iam_policy.security_contact_policy.arn
}

resource "aws_iam_group_policy_attachment" "billing_contact_policy_attachment" {
  group      = aws_iam_group.account_contacts.name
  policy_arn = aws_iam_policy.billing_contact_policy.arn
}

resource "aws_iam_group_policy_attachment" "operations_contact_policy_attachment" {