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
    name      = "ConsoleLoginFailures"
    namespace = "SecurityMetrics"
    value     = "1"
  }
}

# Create a CloudWatch alarm for the ConsoleLogin failures metric
resource "aws_cloudwatch_metric_alarm" "authentication_failures_alarm" {
  alarm_name          = "ConsoleLoginFailuresAlarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "ConsoleLoginFailures"
  namespace           = "SecurityMetrics"
  period              = "60"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Alarm when there are AWS Management Console authentication failures"
  alarm_actions       = ["arn:aws:sns:ap-northeast-2:132410971304:security-alerts"]
}


This Terraform code does the following:

1. Configures the AWS provider for the ap-northeast-2 region.
2. Creates a CloudWatch Logs metric filter for `ConsoleLogin` failures, where the error message is "Failed authentication".
3. Creates a CloudWatch alarm for the `ConsoleLoginFailures` metric, which will trigger an alarm when the number of failures is greater than or equal to 1 in a 1-minute period.
4. The alarm action is set to an SNS topic with the ARN `arn:aws:sns:ap-northeast-2:132410971304:security-alerts`, which can be used to send notifications to the appropriate incident response team.