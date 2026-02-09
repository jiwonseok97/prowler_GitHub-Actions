# Retrieve the existing CloudWatch log group name using a data source
data "aws_cloudwatch_log_group" "existing_log_group" {
  name = "arn:aws:logs:ap-northeast-2:132410971304:log-group"
}

# Create a CloudWatch log metric filter for console login without MFA
resource "aws_cloudwatch_log_metric_filter" "remediation_console_login_without_mfa" {
  name           = "console-login-without-mfa"
  pattern        = "{$.eventName = \"ConsoleLogin\" && $.additionalEventData.MFAUsed != \"Yes\"}"
  log_group_name = data.aws_cloudwatch_log_group.existing_log_group.name

  metric_transformation {
    name      = "ConsoleLoginWithoutMFA"
    namespace = "SecurityMetrics"
    value     = "1"
  }
}

# Create a CloudWatch alarm for the console login without MFA metric
resource "aws_cloudwatch_metric_alarm" "remediation_console_login_without_mfa_alarm" {
  alarm_name          = "console-login-without-mfa-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "ConsoleLoginWithoutMFA"
  namespace           = "SecurityMetrics"
  period              = "60"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Alarm when console login without MFA is detected"
  alarm_actions       = [aws_sns_topic.remediation_security_alerts.arn]
}

# Create an SNS topic for security alerts
resource "aws_sns_topic" "remediation_security_alerts" {
  name = "security-alerts"
}