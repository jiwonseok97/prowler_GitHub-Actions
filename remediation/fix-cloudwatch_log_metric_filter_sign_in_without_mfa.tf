# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Create a CloudWatch log metric filter to detect console logins without MFA
resource "aws_cloudwatch_log_metric_filter" "console_login_without_mfa" {
  name           = "console-login-without-mfa"
  pattern        = "{$.eventName = \"ConsoleLogin\" && $.additionalEventData.MFAUsed != \"Yes\"}"
  log_group_name = "arn:aws:logs:ap-northeast-2:132410971304:log-group"

  metric_transformation {
    name      = "ConsoleLoginsWithoutMFA"
    namespace = "MyApp/SecurityMetrics"
    value     = "1"
  }
}

# Create a CloudWatch alarm to trigger when console logins without MFA are detected
resource "aws_cloudwatch_metric_alarm" "console_login_without_mfa_alarm" {
  alarm_name          = "console-login-without-mfa-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "ConsoleLoginsWithoutMFA"
  namespace           = "MyApp/SecurityMetrics"
  period              = "60"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Alarm when console logins without MFA are detected"
  alarm_actions       = ["arn:aws:sns:ap-northeast-2:132410971304:my-security-alerts"]
}


This Terraform code does the following:

1. Configures the AWS provider for the ap-northeast-2 region.
2. Creates a CloudWatch log metric filter to detect console logins without MFA. The filter looks for the `ConsoleLogin` event where the `MFAUsed` field is not "Yes".
3. Creates a CloudWatch metric alarm that triggers when the number of console logins without MFA (as detected by the metric filter) is greater than or equal to 1 in a 1-minute period. The alarm is configured to send notifications to the "arn:aws:sns:ap-northeast-2:132410971304:my-security-alerts" SNS topic.