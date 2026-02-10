# Detach the AWSCloudShellFullAccess policy from all IAM identities
resource "aws_iam_policy_attachment" "remediation_detach_cloudshell_admin_policy" {
  name       = "remediation-detach-cloudshell-admin-policy"
  policy_arn = "arn:aws:iam::aws:policy/AWSCloudShellFullAccess"
  users      = []
  groups     = []
  roles      = []
}