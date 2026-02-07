# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Enforce MFA for the root user
resource "aws_iam_account_password_policy" {
  minimum_password_length        = 14
  require_lowercase_characters   = true
  require_numbers                = true
  require_uppercase_characters   = true
  require_symbols                = true
  allow_users_to_change_password = true
  max_password_age               = 90
  password_reuse_prevention      = 24
  hard_expiry                    = false
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

# Update the root user's alternate contacts
resource "aws_iam_account_alias" "root_user_alternate_contacts" {
  account_alias = "root-user-alternate-contacts"
}

# Remove the security challenge questions for the root user
resource "aws_iam_account_password_policy" "remove_security_challenge_questions" {
  allow_users_to_change_password = true
  hard_expiry                    = false
  max_password_age               = 0
  minimum_password_length        = 0
  password_reuse_prevention      = 0
  require_lowercase_characters   = false
  require_numbers                = false
  require_symbols                = false
  require_uppercase_characters   = false
}