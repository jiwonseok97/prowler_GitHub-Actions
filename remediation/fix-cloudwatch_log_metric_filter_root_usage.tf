# Use data source to look up the existing CloudWatch log group
data "aws_cloudwatch_log_group" "remediation_root_usage" {
  name = "log-group"
}

# Create a CloudWatch Logs metric filter for root account usage
resource "aws_cloudwatch_log_metric_filter" "remediation_root_usage" {
  name           = "remediation-root-usage"
  pattern        = "{$.userIdentity.type = \"Root\" && $.userIdentity.invokedBy NOT EXISTS && $.eventType != \"AwsServiceEvent\"}"
  log_group_name = data.aws_cloudwatch_log_group.remediation_root_usage.name

  metric_transformation {
    name      = "RootUsage"
    namespace = "MyApp/Audit"
    value     = "1"
  }
}

# Create a CloudWatch alarm for the root account usage metric
resource "aws_cloudwatch_metric_alarm" "remediation_root_usage_alarm" {
  alarm_name          = "remediation-root-usage-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "RootUsage"
  namespace           = "MyApp/Audit"
  period              = 60
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Alarm when root account is used"
  alarm_actions       = [aws_sns_topic.remediation_root_usage_alert.arn]
}

# Create an SNS topic for the root usage alarm
resource "aws_sns_topic" "remediation_root_usage_alert" {
  name = "remediation-root-usage-alert"
}