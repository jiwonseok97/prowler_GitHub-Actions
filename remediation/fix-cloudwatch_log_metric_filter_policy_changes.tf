# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Create a CloudWatch Logs metric filter for IAM policy changes
resource "aws_cloudwatch_log_metric_filter" "iam_policy_changes" {
  name           = "iam-policy-changes"
  pattern        = "{$.eventName = CreatePolicy} || {$.eventName = DeletePolicy} || {$.eventName = UpdatePolicy} || {$.eventName = AttachPolicyToRole} || {$.eventName = DetachPolicyFromRole} || {$.eventName = AttachUserPolicy} || {$.eventName = DetachUserPolicy} || {$.eventName = AttachGroupPolicy} || {$.eventName = DetachGroupPolicy}"
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
  alarm_description   = "Alarm when an IAM policy is created, updated, deleted, attached or detached"
  alarm_actions       = ["arn:aws:sns:ap-northeast-2:132410971304:security-alerts"]
}


The provided Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Creates a CloudWatch Logs metric filter for IAM policy changes, including events for creating, deleting, updating, attaching, and detaching policies.
3. Creates a CloudWatch alarm for the IAM policy changes metric filter, which will trigger an alarm when any of the specified events occur. The alarm is configured to send notifications to an SNS topic with the ARN `arn:aws:sns:ap-northeast-2:132410971304:security-alerts`.

This code addresses the security finding by creating the necessary CloudWatch Logs metric filter and alarm to monitor and alert on IAM policy changes, as recommended in the finding.