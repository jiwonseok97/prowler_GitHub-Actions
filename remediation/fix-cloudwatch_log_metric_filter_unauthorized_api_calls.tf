# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Get the existing CloudWatch Logs log group
data "aws_cloudwatch_log_group" "unauthorized_api_calls" {
  name = "arn:aws:logs:ap-northeast-2:132410971304:log-group"
}

# Create a CloudWatch Logs metric filter for unauthorized API calls
resource "aws_cloudwatch_log_metric_filter" "unauthorized_api_calls" {
  name           = "UnauthorizedAPICalls"
  pattern        = "{ ($.errorCode = *UnauthorizedOperation) || ($.errorCode = AccessDenied*) }"
  log_group_name = data.aws_cloudwatch_log_group.unauthorized_api_calls.name

  metric_transformation {
    name      = "UnauthorizedAPICalls"
    namespace = "SecurityMetrics"
    value     = "1"
  }
}

# Create a CloudWatch alarm for the unauthorized API calls metric
resource "aws_cloudwatch_metric_alarm" "unauthorized_api_calls" {
  alarm_name          = "UnauthorizedAPICalls"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = aws_cloudwatch_log_metric_filter.unauthorized_api_calls.metric_transformation[0].name
  namespace           = aws_cloudwatch_log_metric_filter.unauthorized_api_calls.metric_transformation[0].namespace
  period              = "60"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Alarm for unauthorized API calls"
  alarm_actions       = ["arn:aws:sns:ap-northeast-2:132410971304:your-sns-topic-arn"]
}


This Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Retrieves the existing CloudWatch Logs log group using the `data` source.
3. Creates a CloudWatch Logs metric filter for unauthorized API calls, using the pattern `{ ($.errorCode = *UnauthorizedOperation) || ($.errorCode = AccessDenied*) }`.
4. Creates a CloudWatch alarm for the unauthorized API calls metric, which will trigger when the metric value is greater than or equal to 1. The alarm action is set to an SNS topic, which you'll need to replace with your own SNS topic ARN.