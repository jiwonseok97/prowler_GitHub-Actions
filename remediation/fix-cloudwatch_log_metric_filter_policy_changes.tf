# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Create a CloudWatch Logs metric filter for IAM policy changes
resource "aws_cloudwatch_log_metric_filter" "iam_policy_changes" {
  name           = "iam-policy-changes"
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
  log_group_name = "arn:aws:logs:ap-northeast-2:132410971304:log-group"
  metric_transformation {
    name      = "IAMPolicyChanges"
    namespace = "MyApp/SecurityLogs"
    value     = "1"
  }
}

# Create a CloudWatch alarm for the IAM policy changes metric filter
resource "aws_cloudwatch_metric_alarm" "iam_policy_changes_alarm" {
  alarm_name          = "iam-policy-changes-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "IAMPolicyChanges"
  namespace           = "MyApp/SecurityLogs"
  period              = "60"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "Alarm when there are IAM policy changes"
  alarm_actions       = ["arn:aws:sns:ap-northeast-2:132410971304:my-security-topic"]
}


The provided Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Creates a CloudWatch Logs metric filter for IAM policy changes, including events such as `CreatePolicy`, `DeletePolicy`, `UpdatePolicy`, `CreatePolicyVersion`, `DeletePolicyVersion`, `AttachUserPolicy`, `DetachUserPolicy`, `AttachGroupPolicy`, `DetachGroupPolicy`, `AttachRolePolicy`, and `DetachRolePolicy`.
3. Defines the metric transformation for the IAM policy changes, naming it `IAMPolicyChanges` and placing it in the `MyApp/SecurityLogs` namespace.
4. Creates a CloudWatch alarm for the `IAMPolicyChanges` metric, triggering when the metric value is greater than or equal to 0. The alarm is configured to send notifications to the `arn:aws:sns:ap-northeast-2:132410971304:my-security-topic` SNS topic.

This Terraform code addresses the security finding by creating a metric filter and an alarm to monitor and notify on IAM policy changes, which is a recommended practice to improve security and compliance.