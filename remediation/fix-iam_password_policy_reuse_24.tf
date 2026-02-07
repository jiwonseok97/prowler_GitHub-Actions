# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Create an IAM password policy to prevent reuse of the last 24 passwords
resource "aws_iam_account_password_policy" "strict" {
  # Require at least one uppercase letter
  require_uppercase_characters = true
  # Require at least one lowercase letter
  require_lowercase_characters = true
  # Require at least one number
  require_numbers = true
  # Require at least one non-alphanumeric character
  require_symbols = true
  # Minimum password length
  minimum_password_length = 14
  # Password cannot be reused within the last 24 passwords
  password_reuse_prevention = 24
  # Passwords expire after 90 days
  max_password_age = 90
  # Prevent password reuse
  allow_users_to_change_password = true
}