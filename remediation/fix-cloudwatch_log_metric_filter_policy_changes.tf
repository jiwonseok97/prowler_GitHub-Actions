# Create a CloudWatch Logs metric filter to capture IAM policy changes
resource "aws_cloudwatch_log_metric_filter" "remediation_iam_policy_changes" {
  name = "remediation-iam-policy-changes"
  pattern        = <<PATTERN
{ ($.eventName = CreatePolicy) || ($.eventName = DeletePolicy) || ($.eventName = UpdatePolicy) || ($.eventName = CreatePolicyVersion) || ($.eventName = DeletePolicyVersion) || ($.eventName = AttachUserPolicy) || ($.eventName = DetachUserPolicy) || ($.eventName = AttachGroupPolicy) || ($.eventName = DetachGroupPolicy) || ($.eventName = AttachRolePolicy) || ($.eventName = DetachRolePolicy) }
PATTERN
  log_group_name = "132410971304"
  metric_transformation {
    name = "IAMPolicyEvent"
    namespace = "SecurityMetrics"
    value     = "1"
  }
}

# Create a CloudWatch alarm to trigger on IAM policy changes
resource "aws_cloudwatch_metric_alarm" "remediation_iam_policy_changes_alarm" {
  alarm_name          = "remediation-iam-policy-changes-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "IAMPolicyEvent"
  namespace           = "SecurityMetrics"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Alarm when an IAM policy is created, updated, or deleted"
  alarm_actions       = [data.aws_sns_topic.remediation_sns_topic.arn]
}

# Use a data source to reference an existing SNS topic for the alarm
data "aws_sns_topic" "remediation_sns_topic" {
  name = "remediation-sns-topic"
}