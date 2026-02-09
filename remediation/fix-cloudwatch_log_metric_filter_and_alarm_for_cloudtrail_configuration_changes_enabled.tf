# Retrieve the existing CloudWatch Logs log group name
data "aws_cloudwatch_log_group" "existing_log_group" {
  name = "arn:aws:logs:ap-northeast-2:132410971304:log-group"
}

# Create a CloudWatch Logs metric filter for CloudTrail configuration changes
resource "aws_cloudwatch_log_metric_filter" "remediation_cloudtrail_config_changes" {
  name           = "remediation-cloudtrail-config-changes"
  pattern        = <<PATTERN
{ ($.eventName = CreateTrail) || ($.eventName = UpdateTrail) || ($.eventName = DeleteTrail) || ($.eventName = StartLogging) || ($.eventName = StopLogging) }
PATTERN
  log_group_name = data.aws_cloudwatch_log_group.existing_log_group.name

  metric_transformation {
    name      = "CloudTrailConfigChanges"
    namespace = "MyApp/CloudTrail"
    value     = "1"
  }
}

# Create a CloudWatch alarm for the CloudTrail configuration changes metric filter
resource "aws_cloudwatch_metric_alarm" "remediation_cloudtrail_config_changes_alarm" {
  alarm_name          = "remediation-cloudtrail-config-changes-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods   = 1
  metric_name         = "CloudTrailConfigChanges"
  namespace           = "MyApp/CloudTrail"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Alarm when CloudTrail configuration changes occur"
  alarm_actions       = ["arn:aws:sns:ap-northeast-2:132410971304:my-alarm-topic"]
}