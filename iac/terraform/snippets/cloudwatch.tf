# CloudWatch remediation baseline snippet
# Minimal log group + metric filter + alarm (no SNS actions)

resource "aws_cloudwatch_log_group" "remediation_cloudwatch_log_group" {
  name              = "remediation-cloudwatch-log-group"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_metric_filter" "remediation_cloudwatch_metric_filter" {
  name           = "remediation-cloudwatch-metric-filter"
  pattern        = "{ $.eventName = \"ConsoleLogin\" }"
  log_group_name = aws_cloudwatch_log_group.remediation_cloudwatch_log_group.name

  metric_transformation {
    name      = "RemediationMetric"
    namespace = "Remediation/CloudWatch"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "remediation_cloudwatch_metric_alarm" {
  alarm_name          = "remediation-cloudwatch-metric-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = aws_cloudwatch_log_metric_filter.remediation_cloudwatch_metric_filter.metric_transformation[0].name
  namespace           = aws_cloudwatch_log_metric_filter.remediation_cloudwatch_metric_filter.metric_transformation[0].namespace
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Alarm triggered by remediation metric filter"
}
