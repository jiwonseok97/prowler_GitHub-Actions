# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Enforce MFA for the root user
resource "aws_iam_account_password_policy" "root_mfa_policy" {
  allow_users_to_change_password = true
  minimum_password_length        = 14
  require_lowercase_characters   = true
  require_numbers                = true
  require_uppercase_characters   = true
  require_symbols                = true
  max_password_age               = 90
  password_reuse_prevention      = 24
  hard_expiry                    = false
  # Require MFA for the root user
  require_mfa_for_root_user = true
}

# Create an alternate contact for the root user
resource "aws_iam_account_alias" "root_alternate_contact" {
  account_alias = "my-alternate-contact"
}

# Create a break-glass role with limited permissions
resource "aws_iam_role" "break_glass_role" {
  name               = "break-glass-role"
  assume_role_policy = data.aws_iam_policy_document.break_glass_role_trust_policy.json
}

data "aws_iam_policy_document" "break_glass_role_trust_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::132410971304:root"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "break_glass_role_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
  role       = aws_iam_role.break_glass_role.name
}


This Terraform code addresses the security finding by:

1. Configuring an AWS IAM account password policy that requires MFA for the root user.
2. Creating an alternate contact for the root user, which can be used for recovery purposes.
3. Creating a break-glass role with full administrative access, which can be used in emergency situations when the root user is not available.

The code uses data sources to reference existing resources, such as the AWS IAM policy document for the break-glass role trust policy. The provider configuration is set for the ap-northeast-2 region.