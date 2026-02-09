# Get the existing CloudWatch Logs log group name
data "aws_cloudwatch_log_group" "existing_log_group" {
  name = "arn:aws:logs:ap-northeast-2:132410971304:log-group"
}

# Create a CloudWatch Logs metric filter for unauthorized API calls
resource "aws_cloudwatch_log_metric_filter" "remediation_unauthorized_api_calls" {
  name           = "remediation-unauthorized-api-calls"
  pattern        = "{ $.errorCode = \"*UnauthorizedOperation\" || $.errorCode = \"AccessDenied*\" }"
  log_group_name = data.aws_cloudwatch_log_group.existing_log_group.name

  metric_transformation {
    name      = "UnauthorizedApiCalls"
    namespace = "SecurityMetrics"
    value     = "1"
  }
}

# Create a CloudWatch alarm for the unauthorized API calls metric
resource "aws_cloudwatch_metric_alarm" "remediation_unauthorized_api_calls_alarm" {
  alarm_name          = "remediation-unauthorized-api-calls-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "UnauthorizedApiCalls"
  namespace           = "SecurityMetrics"
  period              = "60"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Alarm when there are unauthorized API calls"
  alarm_actions       = ["arn:aws:sns:ap-northeast-2:132410971304:my-security-topic"]
}