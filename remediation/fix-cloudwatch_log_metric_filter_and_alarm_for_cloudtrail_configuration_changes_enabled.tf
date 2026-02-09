provider "aws" {
  region = "ap-northeast-2"
}

# Create a CloudWatch Logs metric filter for CloudTrail configuration changes
resource "aws_cloudwatch_log_metric_filter" "cloudtrail_configuration_changes" {
  name           = "cloudtrail-configuration-changes"
  pattern        = <<PATTERN