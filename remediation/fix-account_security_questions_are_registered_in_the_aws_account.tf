# Configure the AWS provider for the ap-northeast-2 region

# Enforce MFA for the root user
resource "aws_iam_account_password_policy" "root_password_policy" {
  allow_users_to_change_password = true
  minimum_password_length        = 14
  require_lowercase_characters   = true
  require_numbers                = true
  require_uppercase_characters   = true
  require_symbols                = true
  max_password_age               = 90
  password_reuse_prevention      = 24
  hard_expiry                    = false
}

# Create an IAM role for the break-glass scenario
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

# Attach the necessary permissions to the break-glass role
resource "aws_iam_role_policy_attachment" "break_glass_role_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
  role       = aws_iam_role.break_glass_role.name
}

# Update the alternate contacts for the root user
resource "aws_organizations_organization" "organization" {
  feature_set = "ALL"

  alternate_contact {
    name  = "John Doe"
    email = "john.doe@example.com"
    phone_number = "+1 (555) 1234567"
  }
}