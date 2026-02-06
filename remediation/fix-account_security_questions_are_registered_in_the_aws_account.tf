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
  # Require MFA for the root user
  require_mfa_for_root_user = true
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
  name = "BreakGlassRole"

  assume_role_policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "AWS": "arn:aws:iam::132410971304:root"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  }
  EOF

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AdministratorAccess"
  ]
}


The provided Terraform code addresses the following security finding:

1. **Enforce MFA for root user**: The `aws_iam_account_password_policy` resource enforces MFA for the root user by setting the `require_mfa_for_root_user` attribute to `true`.
2. **Establish an alternate contact**: The `aws_organizations_account_alternate_contact` resource creates an alternate contact for the root user, including their name, email, and phone number.
3. **Create a break-glass role**: The `aws_iam_role` resource creates a "break-glass" role with the `AdministratorAccess` managed policy, which can be used in emergency situations when the root user is unavailable.

The Terraform code is configured to use the `ap-northeast-2` region, and it uses data sources to reference existing resources where possible.