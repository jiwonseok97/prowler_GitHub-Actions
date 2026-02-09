# Create a new IAM password policy with the required symbol character rule
resource "aws_iam_account_password_policy" "remediation_password_policy" {
  minimum_password_length        = 14
  require_lowercase_characters   = true
  require_uppercase_characters   = true
  require_numbers                = true
  require_symbols                = true
  allow_users_to_change_password = true
  password_reuse_prevention      = 24
}