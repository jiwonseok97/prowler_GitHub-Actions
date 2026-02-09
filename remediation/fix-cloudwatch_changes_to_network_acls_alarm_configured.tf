# Create a data source to look up the existing CloudWatch log group
data "aws_cloudwatch_log_group" "remediation_log_group" {
  name = "arn:aws:logs:ap-northeast-2:132410971304:log-group"
}

# Create a CloudWatch log metric filter for NACL changes
resource "aws_cloudwatch_log_metric_filter" "remediation_nacl_changes" {
  name           = "remediation-nacl-changes"
  pattern        = "{$.eventName = CreateNetworkAcl} || {$.eventName = CreateNetworkAclEntry} || {$.eventName = DeleteNetworkAcl} || {$.eventName = DeleteNetworkAclEntry} || {$.eventName = ReplaceNetworkAclEntry} || {$.eventName = ReplaceNetworkAclAssociation}"
  log_group_name = data.aws_cloudwatch_log_group.remediation_log_group.name

  metric_transformation {
    name      = "NACLChanges"
    namespace = "SecurityMetrics"
    value     = "1"
  }
}

# Create a CloudWatch alarm for NACL changes
resource "aws_cloudwatch_metric_alarm" "remediation_nacl_changes_alarm" {
  alarm_name          = "remediation-nacl-changes-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "NACLChanges"
  namespace           = "SecurityMetrics"
  period              = "60"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Alarm when NACL changes occur"
  alarm_actions       = [aws_sns_topic.remediation_security_alerts.arn]
}

# Create an SNS topic for security alerts
resource "aws_sns_topic" "remediation_security_alerts" {
  name = "remediation-security-alerts"
}