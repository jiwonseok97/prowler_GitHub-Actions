provider "aws" {
  region = "ap-northeast-2"
}

# Create a CloudWatch log metric filter to detect DisableKey and ScheduleKeyDeletion events
resource "aws_cloudwatch_log_metric_filter" "kms_key_deletion_filter" {
  name           = "kms-key-deletion-filter"
  pattern        = "{$.eventName = DisableKey} || {$.eventName = ScheduleKeyDeletion}"
  log_group_name = data.aws_cloudwatch_log_group.existing_log_group.name

  metric_transformation {
    name      = "KMSKeyDisabledOrDeleted"
    namespace = "SecurityMetrics"
    value     = "1"