# Modify the existing IAM role to disable cross-account sharing

# Attach a custom policy to the IAM role to restrict cross-account access
resource "aws_iam_role_policy" "remediation_cloudwatch_cross_account_sharing_disabled" {
  name = "remediation-cloudwatch-cross-account-sharing-disabled"
  role = "132410971304"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Deny",
        Action = [
          "cloudwatch:GetMetricData",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics"
        ],
        Resource = "*",
        Condition = {
          "StringNotEquals" = {
            "aws:PrincipalAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}