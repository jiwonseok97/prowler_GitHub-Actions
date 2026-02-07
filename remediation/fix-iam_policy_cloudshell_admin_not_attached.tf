# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Get a list of all IAM users, groups, and roles that have the AWSCloudShellFullAccess policy attached
data "aws_iam_policy_attachment" "cloudshell_admin" {
  name = "AWSCloudShellFullAccess"
}

# Detach the AWSCloudShellFullAccess policy from all identified IAM identities
resource "aws_iam_policy_attachment" "detach_cloudshell_admin" {
  for_each = toset(data.aws_iam_policy_attachment.cloudshell_admin.users)
  name       = "detach-cloudshell-admin"
  users      = [each.value]
  policy_arn = "arn:aws:iam::aws:policy/AWSCloudShellFullAccess"
}

resource "aws_iam_policy_attachment" "detach_cloudshell_admin_groups" {
  for_each = toset(data.aws_iam_policy_attachment.cloudshell_admin.groups)
  name       = "detach-cloudshell-admin-groups"
  groups     = [each.value]
  policy_arn = "arn:aws:iam::aws:policy/AWSCloudShellFullAccess"
}

resource "aws_iam_policy_attachment" "detach_cloudshell_admin_roles" {
  for_each = toset(data.aws_iam_policy_attachment.cloudshell_admin.roles)
  name       = "detach-cloudshell-admin-roles"
  roles      = [each.value]
  policy_arn = "arn:aws:iam::aws:policy/AWSCloudShellFullAccess"
}


This Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Uses a `data` source to get a list of all IAM users, groups, and roles that have the `AWSCloudShellFullAccess` policy attached.
3. Creates three `aws_iam_policy_attachment` resources to detach the `AWSCloudShellFullAccess` policy from the identified IAM users, groups, and roles, respectively.