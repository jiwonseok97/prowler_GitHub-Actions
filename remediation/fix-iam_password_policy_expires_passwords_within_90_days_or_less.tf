# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Create an IAM password policy to enforce password expiration within 90 days or less
resource "aws_iam_account_password_policy" "strict" {
  # Enforce password rotation at <= 90 days
  maximum_password_age = 90
  
  # Prevent password reuse
  password_reuse_prevention = 5
  
  # Require a minimum password length of 14 characters
  minimum_password_length = 14
  
  # Require at least one uppercase letter, one lowercase letter, one number, and one non-alphanumeric character
  require_lowercase_characters = true
  require_uppercase_characters = true
  require_numbers = true
  require_symbols = true
  
  # Allow users to change their own passwords
  allow_users_to_change_password = true
}


This Terraform code creates an IAM password policy that enforces the following requirements:

1. Passwords must be rotated every 90 days or less.
2. Users cannot reuse any of their last 5 passwords.
3. Passwords must be at least 14 characters long.
4. Passwords must contain at least one uppercase letter, one lowercase letter, one number, and one non-alphanumeric character.
5. Users are allowed to change their own passwords.

This policy helps to address the security finding by ensuring that IAM account passwords are rotated regularly and meet strong complexity requirements, reducing the risk of password-related security breaches.