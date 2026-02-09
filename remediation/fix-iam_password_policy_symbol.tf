# Update the IAM password policy to require at least one symbol
resource "aws_iam_account_password_policy" "remediation_remediation" {
  minimum_password_length        = 14
  require_lowercase_characters   = true
  require_numbers                = true
  require_uppercase_characters   = true
  require_symbols                = true
  allow_users_to_change_password = true
}