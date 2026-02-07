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
  alarm_actions       = ["arn:aws:sns:ap-northeast-2:132410971304:my-security-topic"]
}


This Terraform code creates a CloudWatch Logs metric filter for IAM policy changes and an associated CloudWatch alarm. The metric filter tracks events related to creating, deleting, updating, attaching, and detaching IAM policies. The alarm is triggered whenever there is at least one of these events, and it sends a notification to the specified SNS topic.