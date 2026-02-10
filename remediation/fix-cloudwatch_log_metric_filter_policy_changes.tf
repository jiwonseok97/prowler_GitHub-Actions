# Retrieve the existing CloudWatch Logs log group name
data "aws_cloudwatch_log_group" "remediation_iam_policy_changes_log_group" {
  name = "arn:aws:logs:ap-northeast-2:132410971304:log-group"
}

# Create a CloudWatch Logs metric filter to capture IAM policy changes
resource "aws_cloudwatch_log_metric_filter" "remediation_iam_policy_changes" {
  name           = "remediation-iam-policy-changes"
  pattern        = jsonencode({
    eventName = [
      "CreatePolicy", "DeletePolicy", "UpdatePolicy",
      "CreatePolicyVersion", "DeletePolicyVersion",
      "AttachUserPolicy", "DetachUserPolicy",
      "AttachGroupPolicy", "DetachGroupPolicy",
      "AttachRolePolicy", "DetachRolePolicy"
    ]
  })
  log_group_name = data.aws_cloudwatch_log_group.remediation_iam_policy_changes_log_group.name
  metric_transformation {
    name      = "IAMPolicyEvent"
    namespace = "MyApp/SecurityLogs"
    value     = "1"
  }
}

# Create a CloudWatch alarm to notify on IAM policy changes
resource "aws_cloudwatch_metric_alarm" "remediation_iam_policy_changes_alarm" {
  alarm_name          = "remediation-iam-policy-changes-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "IAMPolicyEvent"
  namespace           = "MyApp/SecurityLogs"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Alarm when an IAM policy is created, updated, or deleted"
  alarm_actions       = ["arn:aws:sns:ap-northeast-2:132410971304:my-security-topic"]
}

# Attach an IAM policy to the current IAM user to enforce least privilege for policy changes
resource "aws_iam_user_policy_attachment" "remediation_iam_policy_changes_user_policy" {
  user       = "my-iam-user"
  policy_arn = "arn:aws:iam::aws:policy/IAMUserChangePassword"
}