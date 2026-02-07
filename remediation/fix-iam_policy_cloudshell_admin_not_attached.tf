# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Get a list of all IAM users, groups, and roles that have the AWSCloudShellFullAccess policy attached
data "aws_iam_policy_attachment" "cloudshell_admin_attachment" {
  name = "AWSCloudShellFullAccess"
}

# Detach the AWSCloudShellFullAccess policy from all identified IAM identities
resource "aws_iam_policy_attachment" "remove_cloudshell_admin" {
  name       = "remove-cloudshell-admin"
  policy_arn = "arn:aws:iam::aws:policy/AWSCloudShellFullAccess"
  users      = data.aws_iam_policy_attachment.cloudshell_admin_attachment.users
  groups     = data.aws_iam_policy_attachment.cloudshell_admin_attachment.groups
  roles      = data.aws_iam_policy_attachment.cloudshell_admin_attachment.roles
}


This Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Uses the `aws_iam_policy_attachment` data source to get a list of all IAM users, groups, and roles that have the `AWSCloudShellFullAccess` policy attached.
3. Creates an `aws_iam_policy_attachment` resource to detach the `AWSCloudShellFullAccess` policy from all the identified IAM identities.