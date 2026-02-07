# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Retrieve the existing IAM password policy
data "aws_iam_account_password_policy" "current" {}

# Update the IAM password policy
resource "aws_iam_account_password_policy" "updated" {
  # Require passwords to be at least 14 characters long
  minimum_password_length = 14

  # Require at least one uppercase letter, one lowercase letter, and one number
  require_uppercase_characters = true
  require_lowercase_characters = true
  require_numbers = true

  # Prevent password reuse
  password_reuse_prevention = 24

  # Expire passwords after 90 days
  max_password_age = 90

  # Require MFA for all IAM users
  require_hard_token = true
  allow_users_to_change_password = true
}


This Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Retrieves the existing IAM password policy using the `data` source.
3. Updates the IAM password policy with the following settings:
   - Minimum password length of 14 characters
   - Requirement for at least one uppercase letter, one lowercase letter, and one number
   - Prevention of password reuse for the last 24 passwords
   - Password expiration after 90 days
   - Requirement of MFA for all IAM users
   - Allowing users to change their own passwords