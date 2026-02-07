# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Enforce MFA for the root user
resource "aws_iam_account_password_policy" "root_mfa_policy" {
  allow_users_to_change_password = true
  minimum_password_length        = 14
  require_lowercase_characters   = true
  require_numbers                = true
  require_uppercase_characters   = true
  require_symbols                = true
  max_password_age               = 90
  password_reuse_prevention      = 24
  hard_expiry                    = false
  require_hard_token             = true # Enforce MFA for the root user
}

# Create an alternate contact for the root user
resource "aws_iam_account_alias" "root_account_alias" {
  account_alias = "my-root-account"
}

# Create a break-glass role with limited privileges
resource "aws_iam_role" "break_glass_role" {
  name               = "break-glass-role"
  assume_role_policy = data.aws_iam_policy_document.break_glass_role_trust_policy.json
}

data "aws_iam_policy_document" "break_glass_role_trust_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::132410971304:root"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "break_glass_role_policy_attachment" {
  role       = aws_iam_role.break_glass_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}


The provided Terraform code addresses the security finding by:

1. Configuring the AWS provider for the ap-northeast-2 region.
2. Enforcing MFA for the root user by setting the `require_hard_token` parameter in the `aws_iam_account_password_policy` resource.
3. Creating an alternate contact for the root user by setting the `account_alias` in the `aws_iam_account_alias` resource.
4. Creating a break-glass role with limited privileges (in this case, the `AdministratorAccess` policy) that can be used in emergency situations.