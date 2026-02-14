# Create a CloudWatch Logs metric filter for unauthorized API calls
resource "aws_cloudwatch_log_metric_filter" "remediation_unauthorized_api_calls" {
  name = "remediation-unauthorized-api-calls"
  pattern        = "{ ($.errorCode = '*UnauthorizedOperation') || ($.errorCode = 'AccessDenied*') }"
  log_group_name = "132410971304"

  metric_transformation {
    name = "UnauthorizedApiCalls"
    namespace = "SecurityMetrics"
    value     = "1"
  }
}

# Create a CloudWatch alarm for the unauthorized API calls metric
resource "aws_cloudwatch_metric_alarm" "remediation_unauthorized_api_calls_alarm" {
  alarm_name          = "remediation-unauthorized-api-calls-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = aws_cloudwatch_log_metric_filter.remediation_unauthorized_api_calls.metric_transformation[0].name
  namespace           = aws_cloudwatch_log_metric_filter.remediation_unauthorized_api_calls.metric_transformation[0].namespace
  period              = 60
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Alarm for unauthorized API calls"
  alarm_actions       = [data.aws_sns_topic.existing_topic.arn]
}

# Use a data source to reference an existing SNS topic for the alarm
data "aws_sns_topic" "existing_topic" {
  name = "my-security-notifications"
}