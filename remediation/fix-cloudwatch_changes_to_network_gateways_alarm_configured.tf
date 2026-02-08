provider "aws" {
  region = "ap-northeast-2"
}

# Create a CloudWatch Logs metric filter for the specified log group
# to detect changes to network gateways
resource "aws_cloudwatch_log_metric_filter" "network_gateway_changes" {
  name           = "network-gateway-changes"
  pattern        = <<PATTERN