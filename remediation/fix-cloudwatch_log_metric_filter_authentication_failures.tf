provider "aws" {
  region = "ap-northeast-2"
}

# Create a CloudWatch Logs metric filter for ConsoleLogin failures
resource "aws_cloudwatch_log_metric_filter" "console_login_failures" {
  name           = "console-login-failures"
  pattern        = "{$.eventName = ConsoleLogin && $.errorMessage = \"Failed authentication\"}"
  log_group_name = data.aws_cloudwatch_log_group.existing_log_group.name

  metric_transformation {
    name      = "ConsoleLoginFailures"
    namespace = "MyApp/SecurityMetrics"
    value     = "1"