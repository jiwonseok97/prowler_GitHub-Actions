# Create a CloudWatch Logs metric filter to capture AWS Config configuration changes
resource "aws_cloudwatch_log_metric_filter" "remediation_config_changes_metric_filter" {
  name = "remediation-config-changes-metric-filter"
  pattern        = <<-EOT
    { ($.eventSource = config.amazonaws.com) && (($.eventName = StopConfigurationRecorder) || ($.eventName = DeleteDeliveryChannel) || ($.eventName = PutDeliveryChannel) || ($.eventName = PutConfigurationRecorder)) }
  EOT
  log_group_name = "132410971304"

  metric_transformation {
    name = "ConfigChanges"
    namespace = "MyApp/ConfigChanges"
    value     = "1"
  }
}

# Create a CloudWatch alarm to trigger on the metric filter
resource "aws_cloudwatch_metric_alarm" "remediation_config_changes_alarm" {
  alarm_name          = "remediation-config-changes-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "ConfigChanges"
  namespace           = "MyApp/ConfigChanges"
  period              = 60
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Alarm when AWS Config configuration changes occur"
  alarm_actions       = [data.aws_sns_topic.remediation_sns_topic.arn]
}

# Use a data source to reference an existing SNS topic for alarm notifications
data "aws_sns_topic" "remediation_sns_topic" {
  name = "remediation-notifications"
}