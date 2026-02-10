# Retrieve the existing CloudWatch Logs log group name
data "aws_cloudwatch_log_group" "remediation_log_group" {
  name = "arn:aws:logs:ap-northeast-2:132410971304:log-group"
}

# Create a CloudWatch Logs metric filter for ConsoleLogin failures
resource "aws_cloudwatch_log_metric_filter" "remediation_console_login_failures" {
  name           = "console-login-failures"
  pattern        = "{$.eventName = ConsoleLogin && $.errorMessage = \"Failed authentication\"}"
  log_group_name = data.aws_cloudwatch_log_group.remediation_log_group.name

  metric_transformation {
    name      = "ConsoleLoginFailures"
    namespace = "MyApp/SecurityMetrics"
    value     = "1"
  }
}

# Create a CloudWatch alarm for the ConsoleLogin failures metric
resource "aws_cloudwatch_metric_alarm" "remediation_console_login_failures_alarm" {
  alarm_name          = "console-login-failures-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "ConsoleLoginFailures"
  namespace           = "MyApp/SecurityMetrics"
  period              = 60
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "Alarm when there are 5 or more AWS Management Console authentication failures"
  alarm_actions       = ["arn:aws:sns:ap-northeast-2:132410971304:my-security-notifications"]
}

# Enforce MFA for the AWS account
resource "aws_iam_account_password_policy" "remediation_password_policy" {
  minimum_password_length        = 14
  require_lowercase_characters   = true
  require_numbers                = true
  require_uppercase_characters   = true
  require_symbols                = true
  allow_users_to_change_password = true
  max_password_age               = 90
  password_reuse_prevention      = 24
  hard_expiry                    = false
}

resource "aws_iam_account_alias" "remediation_account_alias" {
  account_alias = "my-secure-account"
}