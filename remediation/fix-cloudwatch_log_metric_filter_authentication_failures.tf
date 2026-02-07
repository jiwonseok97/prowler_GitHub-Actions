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
  alarm_description   = "Alarm when there are 5 or more failed console logins in a 1-minute period"
  alarm_actions       = ["arn:aws:sns:ap-northeast-2:132410971304:security-alerts"]
}


The provided Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Creates a CloudWatch Logs metric filter for `ConsoleLogin` failures, where the `errorMessage` is "Failed authentication". The metric is named `AuthenticationFailures` and is recorded in the `SecurityMetrics` namespace.
3. Creates a CloudWatch alarm for the `AuthenticationFailures` metric, which triggers when the sum of failures is greater than or equal to 5 in a 1-minute period. The alarm action is to send a notification to the `arn:aws:sns:ap-northeast-2:132410971304:security-alerts` SNS topic.