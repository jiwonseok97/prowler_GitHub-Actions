# Create a new IAM password policy with the required uppercase rule
resource "aws_iam_account_password_policy" "remediation_password_policy" {
  minimum_password_length        = 14
  require_lowercase_characters   = true
  require_numbers                = true
  require_symbols                = true
  require_uppercase_characters   = true
  allow_users_to_change_password = true
}

# Create a new IAM user group for users who need to manage the password policy
resource "aws_iam_group" "remediation_password_policy_managers" {
  name = "remediation-password-policy-managers"
}

# Attach a policy to the new group that allows managing the password policy
resource "aws_iam_group_policy" "remediation_password_policy_managers_policy" {
  name  = "remediation-password-policy-managers-policy"
  group = aws_iam_group.remediation_password_policy_managers.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "iam:GetAccountPasswordPolicy",
          "iam:UpdateAccountPasswordPolicy"
        ],
        Resource = "*"
      }
    ]
  })
}