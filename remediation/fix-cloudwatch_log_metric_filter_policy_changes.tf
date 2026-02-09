# Create a CloudWatch log metric filter for IAM policy changes
resource "aws_cloudwatch_log_metric_filter" "remediation_iam_policy_changes" {
  name           = "remediation_iam_policy_changes"
  pattern        = <<PATTERN
{
  ($.eventName = CreatePolicy) || 
  ($.eventName = DeletePolicy) ||
  ($.eventName = UpdatePolicy) ||
  ($.eventName = CreatePolicyVersion) ||
  ($.eventName = DeletePolicyVersion) ||
  ($.eventName = AttachUserPolicy) ||
  ($.eventName = DetachUserPolicy) ||
  ($.eventName = AttachGroupPolicy) ||
  ($.eventName = DetachGroupPolicy) ||
  ($.eventName = AttachRolePolicy) ||
  ($.eventName = DetachRolePolicy)
}
PATTERN
  log_group_name = "/aws/cloudwatch/ap-northeast-2"
  metric_transformation {
    name      = "IAMPolicyChanges"
    namespace = "SecurityMetrics"
    value     = "1"
  }
}

# Create a CloudWatch alarm for the IAM policy changes metric
resource "aws_cloudwatch_metric_alarm" "remediation_iam_policy_changes_alarm" {
  alarm_name          = "remediation_iam_policy_changes_alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "IAMPolicyChanges"
  namespace           = "SecurityMetrics"
  period              = "60"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Alarm when there are IAM policy changes"
  alarm_actions       = ["arn:aws:sns:ap-northeast-2:132410971304:my-security-topic"]
}