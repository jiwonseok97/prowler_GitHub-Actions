# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Create an IAM password policy with the required uppercase rule
resource "aws_iam_account_password_policy" "strong_password_policy" {
  # Require at least one uppercase letter
  require_uppercase_characters = true

  # Also require other password complexity rules
  minimum_password_length        = 14
  require_lowercase_characters   = true
  require_numbers                = true
  require_symbols                = true
  allow_users_to_change_password = true
}