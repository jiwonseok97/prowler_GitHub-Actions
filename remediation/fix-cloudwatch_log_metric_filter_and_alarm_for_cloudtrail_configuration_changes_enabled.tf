# Create a CloudWatch Logs metric filter for CloudTrail configuration changes
resource "aws_cloudwatch_log_metric_filter" "remediation_cloudtrail_configuration_changes_metric_filter" {
  name           = "remediation-cloudtrail-configuration-changes-metric-filter"
  pattern        = <<PATTERN
{ ($.eventName = CreateTrail) || ($.eventName = UpdateTrail) || ($.eventName = DeleteTrail) || ($.eventName = StartLogging) || ($.eventName = StopLogging) }
PATTERN
  log_group_name = "YOUR_CLOUDTRAIL_LOG_GROUP_NAME"

  metric_transformation {
    name      = "CloudTrailConfigurationChanges"
    namespace = "YourCustomNamespace"
    value     = "1"
  }
}

# Create a CloudWatch alarm for the CloudTrail configuration changes metric filter
resource "aws_cloudwatch_metric_alarm" "remediation_cloudtrail_configuration_changes_alarm" {
  alarm_name          = "remediation-cloudtrail-configuration-changes-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = aws_cloudwatch_log_metric_filter.remediation_cloudtrail_configuration_changes_metric_filter.metric_transformation[0].name
  namespace           = aws_cloudwatch_log_metric_filter.remediation_cloudtrail_configuration_changes_metric_filter.metric_transformation[0].namespace
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Alarm when CloudTrail configuration changes occur"
  alarm_actions       = ["arn:aws:sns:ap-northeast-2:132410971304:your-sns-topic-arn"]
}