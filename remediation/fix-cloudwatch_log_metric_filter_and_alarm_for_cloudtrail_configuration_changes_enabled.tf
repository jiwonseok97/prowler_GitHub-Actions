# Create a CloudWatch Logs metric filter for CloudTrail configuration changes
resource "aws_cloudwatch_log_metric_filter" "remediation_cloudtrail_configuration_changes" {
  name = "remediation-cloudtrail-configuration-changes"
  pattern        = "{$.eventName = CreateTrail} || {$.eventName = UpdateTrail} || {$.eventName = DeleteTrail} || {$.eventName = StartLogging} || {$.eventName = StopLogging}"
  log_group_name = "132410971304"

  metric_transformation {
    name = "CloudTrailConfigurationChanges"
    namespace = "CloudTrailConfigurationMetrics"
    value     = "1"
  }
}

# Create a CloudWatch Alarm for the CloudTrail configuration changes metric filter
resource "aws_cloudwatch_metric_alarm" "remediation_cloudtrail_configuration_changes_alarm" {
  alarm_name          = "remediation-cloudtrail-configuration-changes-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CloudTrailConfigurationChanges"
  namespace           = "CloudTrailConfigurationMetrics"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Alarm when CloudTrail configuration changes occur"
  alarm_actions       = [data.aws_sns_topic.existing_sns_topic.arn]
}

# Use a data source to reference an existing SNS topic for the alarm action
data "aws_sns_topic" "existing_sns_topic" {
  name = "existing-sns-topic"
}