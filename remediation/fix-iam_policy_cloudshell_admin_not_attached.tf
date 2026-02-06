# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Get the existing AWSCloudShellFullAccess policy
data "aws_iam_policy" "cloudshell_full_access" {
  name = "AWSCloudShellFullAccess"
}

# Detach the AWSCloudShellFullAccess policy from all IAM identities
resource "aws_iam_policy_attachment" "detach_cloudshell_full_access" {
  name       = "detach-cloudshell-full-access"
  policy_arn = data.aws_iam_policy.cloudshell_full_access.arn
  roles      = []
  users      = []
  groups     = []
}


This Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Retrieves the existing `AWSCloudShellFullAccess` policy using the `data` source.
3. Creates an `aws_iam_policy_attachment` resource to detach the `AWSCloudShellFullAccess` policy from all IAM identities (users, groups, and roles).