# Get the existing CloudWatch Logs log group name
data "aws_cloudwatch_log_group" "existing_log_group" {
  name = "arn:aws:logs:ap-northeast-2:132410971304:log-group"
}

# Create a CloudWatch Logs metric filter to detect root account usage
resource "aws_cloudwatch_log_metric_filter" "remediation_root_usage_metric_filter" {
  name           = "root-usage-metric-filter"
  pattern        = "$$.userIdentity.type = \"Root\" && $$.userIdentity.invokedBy NOT EXISTS && $$.eventType != \"AwsServiceEvent\""
  log_group_name = data.aws_cloudwatch_log_group.existing_log_group.name

  metric_transformation {
    name      = "RootUsage"
    namespace = "SecurityMetrics"
    value     = "1"
  }
}

# Create a CloudWatch alarm to trigger on the root usage metric
resource "aws_cloudwatch_metric_alarm" "remediation_root_usage_alarm" {
  alarm_name          = "root-usage-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "RootUsage"
  namespace           = "SecurityMetrics"
  period              = "60"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Alarm when root account is used"
  alarm_actions       = [aws_sns_topic.remediation_root_usage_alert.arn]
}

# Create an SNS topic to receive the root usage alarm
resource "aws_sns_topic" "remediation_root_usage_alert" {
  name = "root-usage-alert"
}

# Create an SNS topic subscription to send email notifications
resource "aws_sns_topic_subscription" "remediation_root_usage_alert_email" {
  topic_arn = aws_sns_topic.remediation_root_usage_alert.arn
  protocol  = "email"
  endpoint  = "example@example.com"
}