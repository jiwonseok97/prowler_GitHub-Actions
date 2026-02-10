# Retrieve the existing CloudWatch Logs log group name
data "aws_cloudwatch_log_group" "existing_log_group" {
  name = "arn:aws:logs:ap-northeast-2:132410971304:log-group"
}

# Create a CloudWatch Logs metric filter to capture AWS Config configuration changes
resource "aws_cloudwatch_log_metric_filter" "remediation_config_changes" {
  name           = "remediation-config-changes"
  pattern        = <<PATTERN
{ ($.eventSource = config.amazonaws.com) && (($.eventName = StopConfigurationRecorder) || ($.eventName = DeleteDeliveryChannel) || ($.eventName = PutDeliveryChannel) || ($.eventName = PutConfigurationRecorder)) }
PATTERN
  log_group_name = data.aws_cloudwatch_log_group.existing_log_group.name

  metric_transformation {
    name      = "ConfigChanges"
    namespace = "MyApp/Audit"
    value     = "1"
  }
}

# Create a CloudWatch alarm to trigger on the metric filter
resource "aws_cloudwatch_metric_alarm" "remediation_config_changes_alarm" {
  alarm_name          = "remediation-config-changes-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "ConfigChanges"
  namespace           = "MyApp/Audit"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Alarm when AWS Config configuration changes occur"
  alarm_actions       = ["arn:aws:sns:ap-northeast-2:132410971304:my-alarm-topic"]
}