# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Create a CloudWatch Logs metric filter for IAM policy changes
resource "aws_cloudwatch_log_metric_filter" "iam_policy_changes" {
  name           = "iam-policy-changes"
  pattern        = "{$.eventName = CreatePolicy} || {$.eventName = DeletePolicy} || {$.eventName = UpdatePolicy} || {$.eventName = AttachUserPolicy} || {$.eventName = DetachUserPolicy} || {$.eventName = AttachGroupPolicy} || {$.eventName = DetachGroupPolicy} || {$.eventName = AttachRolePolicy} || {$.eventName = DetachRolePolicy}"
  log_group_name = "arn:aws:logs:ap-northeast-2:132410971304:log-group"

  metric_transformation {
    name      = "IAMPolicyChanges"
    namespace = "SecurityMetrics"
    value     = "1"
  }
}

# Create a CloudWatch alarm for the IAM policy changes metric filter
resource "aws_cloudwatch_metric_alarm" "iam_policy_changes_alarm" {
  alarm_name          = "iam-policy-changes-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "IAMPolicyChanges"
  namespace           = "SecurityMetrics"
  period              = "60"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Alarm when there are IAM policy changes"
  alarm_actions       = ["arn:aws:sns:ap-northeast-2:132410971304:security-alerts"]
}


This Terraform code creates a CloudWatch Logs metric filter for IAM policy changes and a CloudWatch alarm that triggers when there are any IAM policy changes. The metric filter monitors for various IAM policy-related events, such as creating, deleting, updating, attaching, and detaching policies. The alarm is set to trigger when the sum of the "IAMPolicyChanges" metric is greater than or equal to 1 within a 60-second period. The alarm action is set to an SNS topic for security alerts.