# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Create an AWS IAM account alias
resource "aws_iam_account_alias" "security_contact" {
  account_alias = "security-contact"
}

# Create an AWS IAM user for the security contact
resource "aws_iam_user" "security_contact" {
  name = "security-contact"
}

# Create an AWS IAM user policy for the security contact
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


This Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Creates an AWS IAM account alias named `security-contact`.
3. Creates an AWS IAM user named `security-contact`.
4. Creates an AWS IAM user policy for the `security-contact` user, which grants the necessary permissions to manage the AWS account's security contact information.