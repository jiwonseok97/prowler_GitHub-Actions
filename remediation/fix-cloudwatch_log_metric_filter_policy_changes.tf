# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Create a CloudWatch Logs metric filter for IAM policy changes
resource "aws_cloudwatch_log_metric_filter" "iam_policy_changes" {
  name           = "iam-policy-changes"
  pattern        = "{$.eventName = CreatePolicy} || {$.eventName = DeletePolicy} || {$.eventName = UpdatePolicy} || {$.eventName = AttachPolicyToRole} || {$.eventName = DetachPolicyFromRole} || {$.eventName = CreatePolicyVersion} || {$.eventName = DeletePolicyVersion}"
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
  alarm_description   = "Alarm when IAM policy changes occur"
  alarm_actions       = ["arn:aws:sns:ap-northeast-2:132410971304:security-alerts"]
}


This Terraform code creates a CloudWatch Logs metric filter for IAM policy changes and an associated CloudWatch alarm. The metric filter monitors for specific IAM policy-related events, such as create, delete, update, attach, and detach, and the alarm is triggered when any of these events occur.

The `aws_cloudwatch_log_metric_filter` resource creates the metric filter, and the `aws_cloudwatch_metric_alarm` resource creates the alarm. The alarm is configured to trigger when the "IAMPolicyChanges" metric is greater than or equal to 1, and it sends an alert to the "security-alerts" SNS topic.