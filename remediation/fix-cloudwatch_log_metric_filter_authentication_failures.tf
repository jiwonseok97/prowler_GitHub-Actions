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
  alarm_description   = "Alarm when there are 5 or more failed console logins"
  alarm_actions       = [aws_sns_topic.remediation_security_alerts.arn]
}

# Create an SNS topic for security alerts
resource "aws_sns_topic" "remediation_security_alerts" {
  name = "security-alerts"
}

# Attach a policy to the SNS topic to allow CloudWatch alarms to publish to it
resource "aws_sns_topic_policy" "remediation_security_alerts_policy" {

  policy = jsonencode({
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        },
        Action = "sns:Publish",
        Resource = aws_sns_topic.remediation_security_alerts.arn
      }
    ]
  })
  arn = aws_sns_topic.remediation_security_alerts.arn
}