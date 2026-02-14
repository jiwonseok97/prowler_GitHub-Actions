# Create a CloudWatch log metric filter and alarm for NACL change events
resource "aws_cloudwatch_log_metric_filter" "remediation_nacl_changes_filter" {
  name = "remediation-nacl-changes-filter"
  pattern        = "{$.eventName = CreateNetworkAcl} || {$.eventName = CreateNetworkAclEntry} || {$.eventName = DeleteNetworkAcl} || {$.eventName = DeleteNetworkAclEntry} || {$.eventName = ReplaceNetworkAclEntry} || {$.eventName = ReplaceNetworkAcl} || {$.eventName = UpdateNetworkAclEntry}"
  log_group_name = "132410971304"

  metric_transformation {
    name = "NACLChanges"
    namespace = "LogMetrics"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "remediation_nacl_changes_alarm" {
  alarm_name          = "remediation-nacl-changes-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "NACLChanges"
  namespace           = "LogMetrics"
  period              = "60"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Alarm when a NACL change event is detected"
  alarm_actions       = [data.aws_sns_topic.existing_topic.arn]
}

# Use a data source to reference an existing SNS topic for the alarm
data "aws_sns_topic" "existing_topic" {
  name = "existing-sns-topic"
}