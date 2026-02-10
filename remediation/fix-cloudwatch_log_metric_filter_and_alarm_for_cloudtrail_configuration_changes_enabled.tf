# Create a CloudWatch Logs metric filter to capture CloudTrail configuration changes
resource "aws_cloudwatch_log_metric_filter" "remediation_cloudtrail_configuration_changes" {
  name           = "remediation-cloudtrail-configuration-changes"
  pattern        = <<PATTERN
{ ($.eventName = CreateTrail) || ($.eventName = UpdateTrail) || ($.eventName = DeleteTrail) || ($.eventName = StartLogging) || ($.eventName = StopLogging) }
PATTERN
  log_group_name = data.aws_cloudwatch_log_group.existing_log_group.name

  metric_transformation {
    name      = "CloudTrailConfigurationChanges"
    namespace = "MyApp/CloudTrail"
    value     = "1"
  }
}

# Create a CloudWatch alarm to trigger on CloudTrail configuration changes
resource "aws_cloudwatch_metric_alarm" "remediation_cloudtrail_configuration_changes_alarm" {
  alarm_name          = "remediation-cloudtrail-configuration-changes-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CloudTrailConfigurationChanges"
  namespace           = "MyApp/CloudTrail"
  period              = "60"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Alarm when CloudTrail configuration changes occur"
  alarm_actions       = [aws_sns_topic.remediation_alert_topic.arn]
}

# Look up the existing CloudWatch Log Group
data "aws_cloudwatch_log_group" "existing_log_group" {
  name = "arn:aws:logs:ap-northeast-2:132410971304:log-group"
}

# Create an SNS topic for the alarm
resource "aws_sns_topic" "remediation_alert_topic" {
  name = "remediation-cloudtrail-configuration-changes-alert"
}