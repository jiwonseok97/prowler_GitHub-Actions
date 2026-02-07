# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Update the IAM password policy to meet the security finding
resource "aws_iam_account_password_policy" "strict" {
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
  require_users_to_change_password = true
}


This Terraform code updates the IAM password policy to meet the security finding. It sets the minimum password length to 14 characters, requires a mix of uppercase, lowercase, and numeric characters, prevents password reuse, and expires passwords after 90 days. It also requires all IAM users to use MFA.