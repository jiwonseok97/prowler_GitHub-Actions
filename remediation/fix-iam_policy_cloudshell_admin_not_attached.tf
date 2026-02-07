# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Detach the AWSCloudShellFullAccess policy from any IAM users, groups, or roles
resource "aws_iam_policy_attachment" "detach_cloudshell_admin" {
  name       = "detach-cloudshell-admin"
  policy_arn = "arn:aws:iam::aws:policy/AWSCloudShellFullAccess"
  roles      = []
  users      = []
  groups     = []
}