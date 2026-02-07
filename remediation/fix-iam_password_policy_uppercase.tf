# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Use the aws_iam_account_password_policy data source to get the current password policy
data "aws_iam_account_password_policy" "current" {}

# Create a new password policy with the uppercase requirement
resource "aws_iam_account_password_policy" "strong" {
  # Require at least one uppercase letter
  require_uppercase_characters = true

  # Require at least one lowercase letter
  require_lowercase_characters = true

  # Require at least one number
  require_numbers = true

  # Require at least one non-alphanumeric character
  require_symbols = true

  # Require a minimum password length of 14 characters
  minimum_password_length = 14

  # Prevent password reuse
  password_reuse_prevention = 24

  # Expire passwords after 90 days
  max_password_age = 90

  # Prevent password changes for 24 hours after creation
  hard_expiry = true
}