provider "aws" {
  region = "ap-northeast-2"
}

# Create a CloudWatch Logs metric filter to detect root account usage
resource "aws_cloudwatch_log_metric_filter" "root_usage" {
  name           = "RootAccountUsage"
  pattern        = "$$.userIdentity.type = \"Root\" && $$.userIdentity.invokedBy NOT EXISTS && $$.eventType != \"AwsServiceEvent\""
  log_group_name = "data.aws_cloudwatch_log_group.existing.name"

  metric_transformation {
    name      = "RootUsage"
    namespace = "SecurityMetrics"
    value     = "1"