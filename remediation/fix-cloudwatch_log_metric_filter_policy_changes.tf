# Retrieve the existing CloudWatch Logs log group name
data "aws_cloudwatch_log_group" "existing_log_group" {
  name = "arn:aws:logs:ap-northeast-2:132410971304:log-group"
}

# Create a CloudWatch Logs metric filter for IAM policy changes
resource "aws_cloudwatch_log_metric_filter" "remediation_iam_policy_changes" {
  name           = "remediation-iam-policy-changes"
  pattern        = jsonencode({
    eventName = [
      "CreatePolicy",
      "DeletePolicy",
      "UpdatePolicy",
      "AttachUserPolicy",
      "DetachUserPolicy",
      "AttachGroupPolicy",
      "DetachGroupPolicy",
      "AttachRolePolicy",
      "DetachRolePolicy"
    ]
  })
  log_group_name = data.aws_cloudwatch_log_group.existing_log_group.name
  metric_transformation {
    name      = "IAMPolicyChanges"
    namespace = "MyApp/SecurityLogs"
    value     = "1"
  }
}

# Create a CloudWatch alarm for the IAM policy changes metric filter
resource "aws_cloudwatch_metric_alarm" "remediation_iam_policy_changes_alarm" {
  alarm_name          = "remediation-iam-policy-changes-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "IAMPolicyChanges"
  namespace           = "MyApp/SecurityLogs"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Alarm when there are IAM policy changes"
  alarm_actions       = ["arn:aws:sns:ap-northeast-2:132410971304:my-security-topic"]
}