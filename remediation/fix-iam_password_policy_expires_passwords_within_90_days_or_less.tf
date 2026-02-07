# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Create an IAM password policy to enforce password expiration within 90 days
resource "aws_iam_account_password_policy" "strict" {
  minimum_password_length        = 14
  require_lowercase_characters   = true
  require_numbers                = true
  require_uppercase_characters   = true
  require_symbols                = true
  allow_users_to_change_password = true
  max_password_age              = 90
  password_reuse_prevention      = 24
}


This Terraform code creates an IAM password policy that enforces the following requirements:

1. Minimum password length of 14 characters
2. Requires at least one lowercase character
3. Requires at least one number
4. Requires at least one uppercase character
5. Requires at least one symbol
6. Allows users to change their own passwords
7. Enforces password expiration within 90 days
8. Prevents password reuse for the last 24 passwords

This policy helps address the security finding by ensuring that IAM user passwords are rotated regularly and cannot be reused, reducing the risk of password-related security breaches.