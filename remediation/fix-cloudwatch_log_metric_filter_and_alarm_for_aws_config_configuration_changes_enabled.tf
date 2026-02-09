provider "aws" {
  region = "ap-northeast-2"
}

# Create a CloudWatch Logs metric filter for AWS Config configuration changes
resource "aws_cloudwatch_log_metric_filter" "config_changes" {
  name           = "config-changes"
  pattern        = <<PATTERN