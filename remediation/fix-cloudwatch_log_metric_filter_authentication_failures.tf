# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Create a CloudWatch Logs metric filter for ConsoleLogin failures
resource "aws_cloudwatch_log_metric_filter" "console_login_failures" {
  name           = "console-login-failures"
  pattern        = "{$.eventName = ConsoleLogin && $.errorMessage = \"Failed authentication\"}"
  log_group_name = "arn:aws:logs:ap-northeast-2:132410971304:log-group"

  metric_transformation {
    name      = "ConsoleLoginFailures"
    namespace = "SecurityMetrics"
    value     = "1"
  }
}

# Create a CloudWatch alarm for the ConsoleLogin failures metric
resource "aws_cloudwatch_metric_alarm" "console_login_failures_alarm" {
  alarm_name          = "console-login-failures-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "ConsoleLoginFailures"
  namespace           = "SecurityMetrics"
  period              = "60"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "Alarm when there are 5 or more failed console logins within 1 minute"
  alarm_actions       = ["arn:aws:sns:ap-northeast-2:132410971304:security-alerts"]
}


The provided Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Creates a CloudWatch Logs metric filter for `ConsoleLogin` failures, where the `errorMessage` is "Failed authentication". The metric is named `ConsoleLoginFailures` and is stored in the `SecurityMetrics` namespace.
3. Creates a CloudWatch alarm for the `ConsoleLoginFailures` metric. The alarm is triggered when the sum of the metric is greater than or equal to 5 within a 1-minute period. When the alarm is triggered, it sends a notification to the `arn:aws:sns:ap-northeast-2:132410971304:security-alerts` SNS topic.