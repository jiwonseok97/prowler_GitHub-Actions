# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Create an IAM password policy to enforce password expiration within 90 days or less
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


The Terraform code above does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Creates an `aws_iam_account_password_policy` resource to enforce the following password policy:
   - Minimum password length of 14 characters
   - Requires at least one lowercase character
   - Requires at least one number
   - Requires at least one uppercase character
   - Requires at least one symbol
   - Allows users to change their own passwords
   - Enforces password expiration within 90 days
   - Prevents password reuse for the last 24 passwords

This should address the security finding by ensuring that IAM account passwords are rotated at least every 90 days and cannot be reused.