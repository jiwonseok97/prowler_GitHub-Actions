# Get the existing CloudWatch log group
data "aws_cloudwatch_log_group" "remediation_log_group" {
  name = "arn:aws:logs:ap-northeast-2:132410971304:log-group"
}

# Create a CloudWatch log metric filter for NACL change events
resource "aws_cloudwatch_log_metric_filter" "remediation_nacl_changes_filter" {
  name           = "nacl-changes-filter"
  pattern        = "{$.eventName = CreateNetworkAcl} || {$.eventName = CreateNetworkAclEntry} || {$.eventName = DeleteNetworkAcl} || {$.eventName = DeleteNetworkAclEntry} || {$.eventName = ReplaceNetworkAclEntry} || {$.eventName = ReplaceNetworkAclAssociation}"
  log_group_name = data.aws_cloudwatch_log_group.remediation_log_group.name

  metric_transformation {
    name      = "NACLChanges"
    namespace = "MyApp/Security"
    value     = "1"
  }
}

# Create a CloudWatch alarm for the NACL change metric
resource "aws_cloudwatch_metric_alarm" "remediation_nacl_changes_alarm" {
  alarm_name          = "nacl-changes-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = aws_cloudwatch_log_metric_filter.remediation_nacl_changes_filter.metric_transformation[0].name
  namespace           = aws_cloudwatch_log_metric_filter.remediation_nacl_changes_filter.metric_transformation[0].namespace
  period              = 60
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Alarm when NACL changes are detected"
  alarm_actions       = ["arn:aws:sns:ap-northeast-2:132410971304:my-security-topic"]
}