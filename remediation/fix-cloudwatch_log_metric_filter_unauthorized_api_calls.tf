# Create a CloudWatch Logs metric filter for unauthorized API calls
resource "aws_cloudwatch_log_metric_filter" "remediation_unauthorized_api_calls" {
  name           = "remediation-unauthorized-api-calls"
  pattern        = "{ $.errorCode = '*UnauthorizedOperation' || $.errorCode = 'AccessDenied*' }"
  log_group_name = "ap-northeast-2-132410971304-log-group"

  metric_transformation {
    name      = "UnauthorizedAPICalls"
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
  alarm_actions       = ["arn:aws:sns:ap-northeast-2:${data.aws_caller_identity.current.account_id}:my-security-notifications"]
}