# CIS AWS Foundations Benchmark - Account password policy
# Covers: expires_passwords, minimum_length_14, number, reuse_24, symbol, uppercase

resource "aws_iam_account_password_policy" "remediation_account_password_policy" {
  minimum_password_length        = 14
  require_uppercase_characters   = true
  require_lowercase_characters   = true
  require_numbers                = true
  require_symbols                = true
  allow_users_to_change_password = true
  hard_expiry                    = false
  password_reuse_prevention      = 24
  max_password_age               = 90
}