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
  alarm_description   = "Alarm when an IAM policy is created, updated, or deleted"
  alarm_actions       = ["arn:aws:sns:ap-northeast-2:132410971304:security-alerts"]
}


This Terraform code creates a CloudWatch Logs metric filter for IAM policy changes and an associated CloudWatch alarm. The metric filter monitors for various IAM policy-related events, such as create, delete, update, attach, and detach. When any of these events occur, the metric filter will capture the event and increment the "IAMPolicyChanges" metric in the "SecurityMetrics" namespace.

The CloudWatch alarm is then configured to monitor the "IAMPolicyChanges" metric and trigger an alarm when the metric value is greater than or equal to 1. The alarm action is set to an SNS topic named "security-alerts", which can be used to notify the appropriate responders.

This solution addresses the security finding by creating the necessary monitoring and alerting for IAM policy changes, which can help enforce least privilege and separation of duties, as well as provide centralized logging and incident response integration.