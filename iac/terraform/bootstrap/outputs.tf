output "role_arn" {
  value = data.aws_iam_role.github_actions.arn
}

output "managed_policies" {
  value = [
    aws_iam_role_policy.terraform_state.name,
    aws_iam_role_policy.remediation_iam.name,
    aws_iam_role_policy.remediation_organizations.name,
    aws_iam_role_policy.remediation_cloudtrail.name,
    aws_iam_role_policy.remediation_cloudwatch.name,
    aws_iam_role_policy.remediation_s3.name,
    aws_iam_role_policy.remediation_kms.name,
    aws_iam_role_policy.remediation_ec2_vpc.name,
    aws_iam_role_policy.remediation_config.name,
    aws_iam_role_policy.remediation_firewall.name,
    aws_iam_role_policy.remediation_ssm.name,
  ]
}
