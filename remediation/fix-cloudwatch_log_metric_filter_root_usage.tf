# Create a CloudWatch Logs metric filter and alarm for root account usage
resource "aws_cloudwatch_log_metric_filter" "remediation_root_usage" {
  name = "root-usage"
  pattern        = "$$.userIdentity.type = \"Root\" && $$.userIdentity.invokedBy NOT EXISTS && $$.eventType != \"AwsServiceEvent\""
  log_group_name = "132410971304"

  metric_transformation {
    name = "RootUsage"
    namespace = "SecurityMetrics"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "remediation_root_usage_alarm" {
  alarm_name          = "root-usage-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "RootUsage"
  namespace           = "SecurityMetrics"
  period              = 60
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Alarm when root account is used"
  alarm_actions       = [data.aws_sns_topic.existing_topic.arn]
}

# Use a data source to reference an existing SNS topic for the alarm action
data "aws_sns_topic" "existing_topic" {
  name = "my-security-notifications"
}