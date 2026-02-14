# CloudWatch remediation baseline snippet
# Log group + metric filter + alarm + SNS notification

resource "aws_cloudwatch_log_group" "remediation_cloudwatch_log_group" {
  name = "remediation-cloudwatch-log-group"
  retention_in_days = 365
}

# SNS topic for alarm notifications
resource "aws_sns_topic" "remediation_security_alerts" {
  name = "remediation-security-alerts"
}

resource "aws_sns_topic_policy" "remediation_security_alerts_policy" {
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudWatchAlarms"
        Effect    = "Allow"
        Principal = { Service = "cloudwatch.amazonaws.com" }
        Action    = "SNS:Publish"
        Resource  = aws_sns_topic.remediation_security_alerts.arn
      }
    ]
  })
  arn = aws_sns_topic.remediation_security_alerts.arn
}

# Metric filter for security events
resource "aws_cloudwatch_log_metric_filter" "remediation_cloudwatch_metric_filter" {
  name = "remediation-cloudwatch-metric-filter"
  pattern        = "{ $.eventName = \"ConsoleLogin\" }"
  log_group_name = aws_cloudwatch_log_group.remediation_cloudwatch_log_group.name

  metric_transformation {
    name = "RemediationMetric"
    namespace = "Remediation/CloudWatch"
    value     = "1"
  }
}

# CloudWatch alarm with SNS notification
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
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.remediation_security_alerts.arn]
}