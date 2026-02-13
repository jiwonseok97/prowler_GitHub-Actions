# Create a CloudWatch log metric filter to detect console logins without MFA
resource "aws_cloudwatch_log_metric_filter" "remediation_console_login_without_mfa" {
  name = "console-login-without-mfa"
  pattern        = "{$.eventName = ConsoleLogin && $.additionalEventData.MFAUsed != \"Yes\"}"
  log_group_name = "132410971304"

  metric_transformation {
    name = "ConsoleLoginWithoutMFA"
    namespace = "MyApp/SecurityMetrics"
    value     = "1"
  }
}

# Create a CloudWatch alarm to trigger on the console login without MFA metric
resource "aws_cloudwatch_metric_alarm" "remediation_console_login_without_mfa_alarm" {
  alarm_name          = "console-login-without-mfa-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "ConsoleLoginWithoutMFA"
  namespace           = "MyApp/SecurityMetrics"
  period              = 60
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Alarm when there is a console login without MFA"
  alarm_actions       = [aws_sns_topic.remediation_security_alerts.arn]
}

# Create an SNS topic to receive the console login without MFA alarm
resource "aws_sns_topic" "remediation_security_alerts" {
  name = "security-alerts"
}

# Attach a policy to the SNS topic to allow CloudWatch to publish messages
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