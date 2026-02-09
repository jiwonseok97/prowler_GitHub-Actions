provider "aws" {
  region = "ap-northeast-2"
}

# Create a CloudWatch log metric filter to detect console logins without MFA
resource "aws_cloudwatch_log_metric_filter" "console_login_without_mfa" {
  name           = "console-login-without-mfa"
  pattern        = "{$.eventName = \"ConsoleLogin\" && $.additionalEventData.MFAUsed != \"Yes\"}"
  log_group_name = data.aws_cloudwatch_log_group.existing_log_group.name

  metric_transformation {
    name      = "ConsoleLoginsWithoutMFA"
    namespace = "MyApp/SecurityMetrics"
    value     = "1"