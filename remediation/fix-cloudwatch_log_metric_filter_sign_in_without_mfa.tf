# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Create a CloudWatch log metric filter for Management Console sign-in without MFA
resource "aws_cloudwatch_log_metric_filter" "sign_in_without_mfa" {
  name           = "sign-in-without-mfa"
  pattern        = "{$.eventName = \"ConsoleLogin\" && $.additionalEventData.MFAUsed != \"Yes\"}"
  log_group_name = "arn:aws:logs:ap-northeast-2:132410971304:log-group"

  metric_transformation {
    name      = "SignInWithoutMFA"
    namespace = "MyApp/SecurityMetrics"
    value     = "1"
  }
}

# Create a CloudWatch alarm for the sign-in without MFA metric
resource "aws_cloudwatch_metric_alarm" "sign_in_without_mfa_alarm" {
  alarm_name          = "sign-in-without-mfa-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "SignInWithoutMFA"
  namespace           = "MyApp/SecurityMetrics"
  period              = "60"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Alarm when there is a sign-in to the Management Console without MFA"
  alarm_actions       = ["arn:aws:sns:ap-northeast-2:132410971304:my-security-alerts"]
}


This Terraform code does the following:

1. Configures the AWS provider for the ap-northeast-2 region.
2. Creates a CloudWatch log metric filter that captures any `ConsoleLogin` events where `MFAUsed` is not "Yes".
3. Creates a CloudWatch alarm that triggers when the `SignInWithoutMFA` metric is greater than or equal to 1, indicating a sign-in to the Management Console without MFA.
4. The alarm is configured to send notifications to an SNS topic named `my-security-alerts`.