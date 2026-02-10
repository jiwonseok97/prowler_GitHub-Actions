# Retrieve the existing CloudWatch Logs log group name
data "aws_cloudwatch_log_group" "existing_log_group" {
  name = "arn:aws:logs:ap-northeast-2:132410971304:log-group"
}

# Create a CloudWatch Logs metric filter to detect root account usage
resource "aws_cloudwatch_log_metric_filter" "remediation_root_usage" {
  name           = "root-account-usage"
  pattern        = "$$.userIdentity.type = \"Root\" && $$.userIdentity.invokedBy NOT EXISTS && $$.eventType != \"AwsServiceEvent\""
  log_group_name = data.aws_cloudwatch_log_group.existing_log_group.name

  metric_transformation {
    name      = "RootUsage"
    namespace = "SecurityMetrics"
    value     = "1"
  }
}

# Create a CloudWatch alarm to trigger on the root account usage metric
resource "aws_cloudwatch_metric_alarm" "remediation_root_usage_alarm" {
  alarm_name          = "root-account-usage-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "RootUsage"
  namespace           = "SecurityMetrics"
  period              = 60
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Alarm when root account is used"
  alarm_actions       = ["arn:aws:sns:ap-northeast-2:132410971304:root-account-usage-alert"]
}