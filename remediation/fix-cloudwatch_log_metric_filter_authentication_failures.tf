# Create a CloudWatch Logs metric filter for ConsoleLogin failures
resource "aws_cloudwatch_log_metric_filter" "remediation_console_login_failures" {
  name = "console-login-failures"
  pattern        = "{$.eventName = ConsoleLogin && $.errorMessage = \"Failed authentication\"}"
  log_group_name = "132410971304"

  metric_transformation {
    name = "ConsoleLoginFailures"
    namespace = "SecurityMetrics"
    value     = "1"
  }
}

# Create a CloudWatch alarm for the ConsoleLogin failures metric
resource "aws_cloudwatch_metric_alarm" "remediation_console_login_failures_alarm" {
  alarm_name          = "console-login-failures-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "ConsoleLoginFailures"
  namespace           = "SecurityMetrics"
  period              = 60
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "Alarm when there are 5 or more AWS Management Console authentication failures"
  alarm_actions       = [data.aws_sns_topic.remediation_sns_topic.arn]
}

# Use a data source to reference an existing SNS topic for the alarm action
data "aws_sns_topic" "remediation_sns_topic" {
  name = "remediation-alerts"
}