provider "aws" {
  region = "ap-northeast-2"
}

# Detach the AWSCloudShellFullAccess policy from all IAM identities
resource "aws_iam_policy_attachment" "detach_cloudshell_admin" {
  name       = "detach-cloudshell-admin"
  policy_arn = "arn:aws:iam::aws:policy/AWSCloudShellFullAccess"
  roles      = []
  users      = []
  groups     = []
}