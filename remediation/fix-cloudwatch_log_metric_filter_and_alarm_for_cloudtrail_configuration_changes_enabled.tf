# Create a CloudWatch Logs metric filter to capture CloudTrail configuration changes
resource "aws_cloudwatch_log_metric_filter" "remediation_cloudtrail_configuration_changes" {
  name = "remediation-cloudtrail-configuration-changes"
  pattern        = <<-EOT
    { ($.eventName = CreateTrail) || ($.eventName = UpdateTrail) || ($.eventName = DeleteTrail) || ($.eventName = StartLogging) || ($.eventName = StopLogging) }
  EOT
  log_group_name = "132410971304"

  metric_transformation {
    name = "CloudTrailConfigurationChanges"
    namespace = "MyApp/CloudTrail"
    value     = "1"
  }
}

# Create a CloudWatch Alarm to notify on CloudTrail configuration changes
resource "aws_cloudwatch_metric_alarm" "remediation_cloudtrail_configuration_changes_alarm" {
  evaluation_periods = 1
  alarm_name          = "remediation-cloudtrail-configuration-changes-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  metric_name         = "CloudTrailConfigurationChanges"
  namespace           = "MyApp/CloudTrail"
  period              = 60
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Alarm when CloudTrail configuration changes are detected"
  alarm_actions       = [data.aws_sns_topic.remediation_sns_topic.arn]
}

# Use a data source to reference an existing SNS topic for the alarm action
data "aws_sns_topic" "remediation_sns_topic" {
  name = "remediation-sns-topic"
}