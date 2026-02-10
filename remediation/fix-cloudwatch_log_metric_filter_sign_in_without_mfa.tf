# Retrieve the existing CloudWatch log group name
data "aws_cloudwatch_log_group" "remediation_log_group" {
  name = "arn:aws:logs:ap-northeast-2:132410971304:log-group"
}

# Create a CloudWatch log metric filter to capture console logins without MFA
resource "aws_cloudwatch_log_metric_filter" "remediation_console_login_without_mfa" {
  name           = "remediation-console-login-without-mfa"
  pattern        = "{$.eventName = \"ConsoleLogin\" && $.additionalEventData.MFAUsed != \"Yes\"}"
  log_group_name = data.aws_cloudwatch_log_group.remediation_log_group.name

  metric_transformation {
    name      = "ConsoleLoginsWithoutMFA"
    namespace = "MyApp/SecurityMetrics"
    value     = "1"
  }
}

# Create a CloudWatch alarm to trigger on console logins without MFA
resource "aws_cloudwatch_metric_alarm" "remediation_console_login_without_mfa_alarm" {
  alarm_name          = "remediation-console-login-without-mfa-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "ConsoleLoginsWithoutMFA"
  namespace           = "MyApp/SecurityMetrics"
  period              = 60
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Alarm when there is a console login without MFA"
  alarm_actions       = ["arn:aws:sns:ap-northeast-2:132410971304:my-security-alerts"]
}