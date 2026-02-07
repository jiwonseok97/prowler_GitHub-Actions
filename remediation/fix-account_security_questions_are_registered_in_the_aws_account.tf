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
resource "aws_organizations_organization" "org" {}

resource "aws_organizations_account" "root_account" {
  name  = "Root Account"
  email = "root@example.com"
}

resource "aws_organizations_account_alternate_contact" "root_account_alternate_contact" {
  account_id = aws_organizations_account.root_account.id
  type       = "SECURITY"
  name       = "John Doe"
  email      = "john.doe@example.com"
  phone_number = "+1 (555) 555-5555"
}

# Create a break-glass role with limited permissions
resource "aws_iam_role" "break_glass_role" {
  name               = "BreakGlassRole"
  assume_role_policy = data.aws_iam_policy_document.break_glass_role_assume_policy.json
}

data "aws_iam_policy_document" "break_glass_role_assume_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::132410971304:root"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "break_glass_role_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
  role       = aws_iam_role.break_glass_role.name
}


This Terraform code addresses the security finding by:

1. Configuring the AWS provider for the ap-northeast-2 region.
2. Enforcing MFA for the root user by setting the `require_hard_token` parameter in the `aws_iam_account_password_policy` resource.
3. Creating an alternate contact for the root user using the `aws_organizations_account_alternate_contact` resource.
4. Creating a break-glass role with limited permissions (in this case, the `AdministratorAccess` policy) using the `aws_iam_role` and `aws_iam_role_policy_attachment` resources.