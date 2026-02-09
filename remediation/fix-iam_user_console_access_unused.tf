# Create a new IAM user with console access disabled
resource "aws_iam_user" "remediation_aws_learner" {
  name = "remediation_aws_learner"
  force_destroy = true
}

# Create a new IAM user login profile with console access disabled
resource "aws_iam_user_login_profile" "remediation_aws_learner_login_profile" {
  user    = aws_iam_user.remediation_aws_learner.name
  pgp_key = "keybase:some_person_that_exists"
  password_length = 20
  password_reset_required = true
}

# Attach the "AdministratorAccess" managed policy to the new IAM user
resource "aws_iam_user_policy_attachment" "remediation_aws_learner_admin_policy" {
  user       = aws_iam_user.remediation_aws_learner.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# Enable MFA for the new IAM user using the AWS CLI or AWS Management Console
# The aws_iam_user_mfa_device resource is not supported in Terraform