# Create a CloudWatch log metric filter to detect disabling or scheduled deletion of KMS keys
resource "aws_cloudwatch_log_metric_filter" "remediation_kms_key_disable_or_delete" {
  name = "remediation-kms-key-disable-or-delete"
  pattern        = "{$.eventName = DisableKey} || {$.eventName = ScheduleKeyDeletion}"
  log_group_name = "132410971304"

  metric_transformation {
    name = "KMSKeyDisableOrDelete"
    namespace = "SecurityMetrics"
    value     = "1"
  }
}

# Create a CloudWatch alarm to trigger on the KMS key disable/delete metric
resource "aws_cloudwatch_metric_alarm" "remediation_kms_key_disable_or_delete_alarm" {
  alarm_name          = "remediation-kms-key-disable-or-delete-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "KMSKeyDisableOrDelete"
  namespace           = "SecurityMetrics"
  period              = "60"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Alarm when a KMS key is disabled or scheduled for deletion"
  alarm_actions       = [aws_sns_topic.remediation_kms_key_disable_or_delete_alarm_topic.arn]
}

# Create an SNS topic to receive the KMS key disable/delete alarm
resource "aws_sns_topic" "remediation_kms_key_disable_or_delete_alarm_topic" {
  name = "remediation-kms-key-disable-or-delete-alarm-topic"
}

# Attach a policy to the SNS topic to allow CloudWatch to publish messages
resource "aws_sns_topic_policy" "remediation_kms_key_disable_or_delete_alarm_topic_policy" {

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        }
        Action = "sns:Publish"
        Resource = aws_sns_topic.remediation_kms_key_disable_or_delete_alarm_topic.arn
      }
    ]
  })
  arn = aws_sns_topic.remediation_kms_key_disable_or_delete_alarm_topic.arn
}