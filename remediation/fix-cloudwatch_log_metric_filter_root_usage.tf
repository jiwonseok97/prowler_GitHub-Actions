# Create a CloudWatch Logs metric filter and alarm for root account usage
resource "aws_cloudwatch_log_metric_filter" "remediation_root_usage" {
  name = "root-usage"
  pattern        = "$$.userIdentity.type = \"Root\" && $$.userIdentity.invokedBy NOT EXISTS && $$.eventType != \"AwsServiceEvent\""
  log_group_name = "132410971304"

  metric_transformation {
    name = "RootUsage"
    namespace = "MyApp/Audit"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "remediation_root_usage_alarm" {
  alarm_name          = "root-usage-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods   = 1
  metric_name         = "RootUsage"
  namespace           = "MyApp/Audit"
  period              = 60
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Alarm when root account is used"
  alarm_actions       = [aws_sns_topic.remediation_root_usage_topic.arn]
}

# Create an SNS topic to receive the root usage alarm
resource "aws_sns_topic" "remediation_root_usage_topic" {
  name = "root-usage-alarm-topic"
}

# Attach a policy to the SNS topic to allow CloudWatch to publish messages
resource "aws_sns_topic_policy" "remediation_root_usage_topic_policy" {

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        },
        Action = "sns:Publish",
        Resource = aws_sns_topic.remediation_root_usage_topic.arn
      }
    ]
  })
  arn = aws_sns_topic.remediation_root_usage_topic.arn
}