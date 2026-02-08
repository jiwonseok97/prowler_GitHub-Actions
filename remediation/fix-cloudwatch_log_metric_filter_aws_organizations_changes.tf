provider "aws" {
  region = "ap-northeast-2"
}

# Create a CloudWatch Logs log group to receive CloudTrail logs
resource "aws_cloudwatch_log_group" "cloudtrail_logs" {
  name = "cloudtrail-logs"
}

# Create a CloudWatch Logs metric filter to detect AWS Organizations changes
resource "aws_cloudwatch_log_metric_filter" "organizations_changes" {
  name           = "organizations-changes"
  pattern        = "{$.eventSource = organizations.amazonaws.com}"
  log_group_name = aws_cloudwatch_log_group.cloudtrail_logs.name

  metric_transformation {
    name      = "OrganizationsChanges"
    namespace = "MyApp/SecurityMetrics"
    value     = "1"