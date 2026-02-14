# Create a CloudWatch log metric filter and alarm for disabling or scheduled deletion of customer-managed KMS keys
resource "aws_cloudwatch_log_metric_filter" "remediation_kms_key_disable_or_delete" {
  name = "remediation-kms-key-disable-or-delete"
  pattern        = "{$.eventName = DisableKey} || {$.eventName = ScheduleKeyDeletion}"
  log_group_name = "132410971304"

  metric_transformation {
    name = "KMSKeyDisabledOrDeleted"
    namespace = "SecurityMetrics"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "remediation_kms_key_disable_or_delete_alarm" {
  alarm_name          = "remediation-kms-key-disable-or-delete-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = aws_cloudwatch_log_metric_filter.remediation_kms_key_disable_or_delete.name
  namespace           = "SecurityMetrics"
  period              = 60
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Alarm when a customer-managed KMS key is disabled or scheduled for deletion"
  alarm_actions       = [data.aws_sns_topic.remediation_sns_topic.arn]
}

# Use a data source to reference an existing SNS topic for the alarm action
data "aws_sns_topic" "remediation_sns_topic" {
  name = "remediation-sns-topic"
}