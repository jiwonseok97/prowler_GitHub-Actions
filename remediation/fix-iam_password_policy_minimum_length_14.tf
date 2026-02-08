provider "aws" {
  region = "ap-northeast-2"
}

# Set the IAM password policy to require at least 14 characters
resource "aws_iam_account_password_policy" "strict" {
  minimum_password_length        = 14
  require_lowercase_characters   = true
  require_uppercase_characters   = true
  require_numbers                = true
  require_symbols                = true
  allow_users_to_change_password = true
  password_reuse_prevention      = 24
}

# Enforce MFA for all IAM users
data "aws_iam_account_alias" "current" {}

resource "aws_iam_account_alias" "current" {
  account_alias = data.aws_iam_account_alias.current.account_alias
}

resource "aws_iam_user_login_profile" "mfa_required" {
  user                    = aws_iam_account_alias.current.account_alias
  password_length         = 16
  password_reset_required = true
}

resource "aws_iam_user_mfa_device" "mfa_required" {
  user = aws_iam_account_alias.current.account_alias
  serial_number = "arn:aws:iam::${data.aws_iam_account_alias.current.account_id}:mfa/${aws_iam_account_alias.current.account_alias}"
  enable_mfa = true
}