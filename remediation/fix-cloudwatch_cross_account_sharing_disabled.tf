provider "aws" {
  region = "ap-northeast-2"
}

# Disable cross-account sharing for CloudWatch Logs
resource "aws_cloudwatch_log_group" "example" {
  name = "example-log-group"