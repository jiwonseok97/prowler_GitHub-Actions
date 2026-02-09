# Create a CloudWatch Logs metric filter and alarm for AWS Config configuration changes
data "aws_cloudwatch_log_group" "config_log_group" {
  name = "arn:aws:logs:ap-northeast-2:132410971304:log-group"
}

resource "aws_cloudwatch_log_metric_filter" "remediation_config_changes" {
  name           = "remediation_config_changes"
  pattern        = <<PATTERN
{ ($.eventSource = config.amazonaws.com) && (($.eventName = StopConfigurationRecorder) || ($.eventName = DeleteDeliveryChannel) || ($.eventName = PutDeliveryChannel) || ($.eventName = PutConfigurationRecorder)) }
PATTERN
  log_group_name = data.aws_cloudwatch_log_group.config_log_group.name

  metric_transformation {
    name      = "ConfigChanges"
    namespace = "MyApp/ConfigChanges"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "remediation_config_changes_alarm" {
  alarm_name          = "remediation_config_changes_alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "ConfigChanges"
  namespace           = "MyApp/ConfigChanges"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Alarm when AWS Config changes are detected"
  alarm_actions       = ["arn:aws:sns:ap-northeast-2:132410971304:my-alarm-topic"]
}