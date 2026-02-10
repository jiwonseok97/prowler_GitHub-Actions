# Update the IAM password policy to require a minimum length of 14 characters
resource "aws_iam_account_password_policy" "remediation_password_policy" {
  minimum_password_length        = 14
  require_lowercase_characters   = true
  require_uppercase_characters   = true
  require_numbers                = true
  require_symbols                = true
  allow_users_to_change_password = true
  max_password_age              = 90
  password_reuse_prevention      = 24
}