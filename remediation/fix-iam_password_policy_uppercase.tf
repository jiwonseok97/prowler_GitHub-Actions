# IAM remediation baseline snippet (targets provided user/role)
# NOTE: This applies account-level password policy (real change)

# Target IAM principal references (for validation and future use)
data "aws_iam_user" "target_user" {
  user_name = "github-actions-prowler"
}

data "aws_iam_role" "target_role" {
  name = "GitHubActionsProwlerRole"
}

# NOTE: IAM permissions for GitHubActionsProwlerRole are managed in
# iac/terraform/bootstrap/ — do not add inline policies here.

# Enforce strict account password policy
resource "aws_iam_account_password_policy" "remediation_account_password_policy" {
  minimum_password_length        = 14
  require_uppercase_characters   = true
  require_lowercase_characters   = true
  require_numbers                = true
  require_symbols                = true
  allow_users_to_change_password = true
  hard_expiry                    = false
  password_reuse_prevention      = 24
  max_password_age               = 90
}