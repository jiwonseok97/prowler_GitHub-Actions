# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Create an IAM account alias for the security contact
resource "aws_iam_account_alias" "security_contact" {
  account_alias = "security-contact"
}

# Create an IAM user for the security contact
resource "aws_iam_user" "security_contact" {
  name = "security-contact"
}

# Create an IAM policy for the security contact user
resource "aws_iam_user_policy" "security_contact_policy" {
  name = "security-contact-policy"
  user = aws_iam_user.security_contact.name

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
        "iam:GetAccountAlias",
        "iam:ListUsers",
        "iam:ListGroups",
        "iam:ListRoles",
        "iam:ListAccessKeys",
        "iam:ListAttachedUserPolicies",
        "iam:ListAttachedGroupPolicies",
        "iam:ListAttachedRolePolicies",
        "iam:ListUserPolicies",
        "iam:ListGroupPolicies",
        "iam:ListRolePolicies",
        "iam:GetUser",
        "iam:GetGroup",
        "iam:GetRole",
        "iam:GetPolicy",
        "iam:GetUserPolicy",
        "iam:GetGroupPolicy",
        "iam:GetRolePolicy"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}


This Terraform code creates an IAM account alias for the security contact, an IAM user for the security contact, and an IAM policy that grants the security contact user the necessary permissions to manage the AWS account's security-related information.

The `aws_iam_account_alias` resource sets the account alias to "security-contact", which can be used to identify the security contact for the AWS account.

The `aws_iam_user` resource creates an IAM user named "security-contact" for the security contact.

The `aws_iam_user_policy` resource creates an IAM policy that grants the security contact user the necessary permissions to view and manage the AWS account's security-related information, such as users, groups, roles, and policies.