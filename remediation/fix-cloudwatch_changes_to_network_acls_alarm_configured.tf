# Create a CloudWatch log metric filter and alarm for NACL change events
resource "aws_cloudwatch_log_metric_filter" "remediation_nacl_changes_filter" {
  name = "remediation-nacl-changes-filter"
  pattern        = "{$.eventName = CreateNetworkAcl} || {$.eventName = CreateNetworkAclEntry} || {$.eventName = DeleteNetworkAcl} || {$.eventName = DeleteNetworkAclEntry} || {$.eventName = ReplaceNetworkAclEntry} || {$.eventName = ReplaceNetworkAcl} || {$.eventName = UpdateNetworkAclEntryWithCidr} || {$.eventName = UpdateNetworkAclEntry}"
  log_group_name = "132410971304"

  metric_transformation {
    name = "NACLChanges"
    namespace = "MyApp/SecurityLogs"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "remediation_nacl_changes_alarm" {
  alarm_name          = "remediation-nacl-changes-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "NACLChanges"
  namespace           = "MyApp/SecurityLogs"
  period              = "60"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Alarm when any NACL change is detected"
  alarm_actions       = [data.aws_sns_topic.remediation_sns_topic.arn]
}

# Reference an existing SNS topic to receive the NACL change alarm
data "aws_sns_topic" "remediation_sns_topic" {
  name = "remediation-sns-topic"
}