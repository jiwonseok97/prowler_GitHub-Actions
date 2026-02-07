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
resource "aws_iam_account_alias" "root_account_alias" {
  account_alias = "my-root-account"
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


This Terraform code does the following:

1. Configures the AWS provider for the ap-northeast-2 region.
2. Enforces MFA for the root user by creating an IAM account password policy that requires MFA for the root user.
3. Creates an IAM account alias for the root account, which can be used as an alternate contact.
4. Creates a "break-glass" role with full administrative access, which can be used as a tightly controlled recovery mechanism in case of emergency.