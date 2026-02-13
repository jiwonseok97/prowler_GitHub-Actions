# Create a CloudWatch Logs metric filter for unauthorized API calls
resource "aws_cloudwatch_log_metric_filter" "remediation_unauthorized_api_calls" {
  name = "remediation-unauthorized-api-calls"
  pattern        = "{ ($.errorCode = '*UnauthorizedOperation') || ($.errorCode = 'AccessDeniedException*') }"
  log_group_name = "132410971304"

  metric_transformation {
    name = "UnauthorizedApiCalls"
    namespace = "SecurityMetrics"
    value     = "1"
  }
}

# Create a CloudWatch alarm for the unauthorized API calls metric
resource "aws_cloudwatch_metric_alarm" "remediation_unauthorized_api_calls_alarm" {
  alarm_name          = "remediation-unauthorized-api-calls-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = aws_cloudwatch_log_metric_filter.remediation_unauthorized_api_calls.metric_transformation[0].name
  namespace           = aws_cloudwatch_log_metric_filter.remediation_unauthorized_api_calls.metric_transformation[0].namespace
  period              = 60
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Alarm when there are unauthorized API calls"
  alarm_actions       = [aws_sns_topic.remediation_unauthorized_api_calls_topic.arn]
}

# Create an SNS topic to receive the alarm notifications
resource "aws_sns_topic" "remediation_unauthorized_api_calls_topic" {
  name = "remediation-unauthorized-api-calls-topic"
}

# Attach a policy to the SNS topic to allow CloudWatch to publish messages
resource "aws_sns_topic_policy" "remediation_unauthorized_api_calls_topic_policy" {

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        }
        Action = "sns:Publish"
        Resource = aws_sns_topic.remediation_unauthorized_api_calls_topic.arn
      }
    ]
  })
  arn = aws_sns_topic.remediation_unauthorized_api_calls_topic.arn
}