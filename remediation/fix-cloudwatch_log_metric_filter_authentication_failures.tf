# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Create a CloudWatch Logs metric filter for ConsoleLogin failures
resource "aws_cloudwatch_log_metric_filter" "authentication_failures" {
  name           = "ConsoleLoginFailures"
  pattern        = "{$.eventName = ConsoleLogin && $.errorMessage = \"Failed authentication\"}"
  log_group_name = "arn:aws:logs:ap-northeast-2:132410971304:log-group"

  metric_transformation {
    name      = "AuthenticationFailures"
    namespace = "SecurityMetrics"
    value     = "1"
  }
}

# Create a CloudWatch alarm for the authentication failures metric
resource "aws_cloudwatch_metric_alarm" "authentication_failures_alarm" {
  alarm_name          = "ConsoleLoginFailuresAlarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "AuthenticationFailures"
  namespace           = "SecurityMetrics"
  period              = "60"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "Alarm when there are 5 or more failed console logins within 1 minute"
  alarm_actions       = ["arn:aws:sns:ap-northeast-2:132410971304:security-alerts"]
}


The provided Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Creates a CloudWatch Logs metric filter named `ConsoleLoginFailures` that captures failed console login attempts with the error message "Failed authentication".
3. Defines a metric transformation for the `AuthenticationFailures` metric in the `SecurityMetrics` namespace, with a value of `1` for each failed login.
4. Creates a CloudWatch alarm named `ConsoleLoginFailuresAlarm` that monitors the `AuthenticationFailures` metric and triggers an alarm when the sum of failures is greater than or equal to 5 within a 1-minute period.
5. The alarm action is set to an SNS topic with the ARN `arn:aws:sns:ap-northeast-2:132410971304:security-alerts`, which can be used to send notifications to the incident response team.