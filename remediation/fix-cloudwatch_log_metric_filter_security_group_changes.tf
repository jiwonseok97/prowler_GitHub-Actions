# Create a CloudWatch Logs metric filter to detect security group changes
resource "aws_cloudwatch_log_metric_filter" "remediation_security_group_changes" {
  name = "remediation-security-group-changes"
  pattern        = "{$.eventName = AuthorizeSecurityGroupIngress} || {$.eventName = AuthorizeSecurityGroupEgress} || {$.eventName = RevokeSecurityGroupIngress} || {$.eventName = RevokeSecurityGroupEgress} || {$.eventName = CreateSecurityGroup} || {$.eventName = DeleteSecurityGroup}"
  log_group_name = "132410971304"

  metric_transformation {
    name = "SecurityGroupChanges"
    namespace = "MyApp/SecurityChanges"
    value     = "1"
  }
}

# Create a CloudWatch alarm to trigger on security group changes
resource "aws_cloudwatch_metric_alarm" "remediation_security_group_changes_alarm" {
  alarm_name          = "remediation-security-group-changes-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "SecurityGroupChanges"
  namespace           = "MyApp/SecurityChanges"
  period              = "60"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Alarm when security group changes occur"
  alarm_actions       = [data.aws_sns_topic.remediation_security_group_changes_topic.arn]
}

# Use a data source to reference an existing SNS topic for the alarm
data "aws_sns_topic" "remediation_security_group_changes_topic" {
  name = "remediation-security-group-changes-topic"
}

# Enforce least privilege on security group changes
# (IAM policy creation and attachment omitted due to IAM Guardrails)

# Use change management and tagging
# (Resource tagging omitted)

# Centralize logs, test alarms, and maintain runbooks
# (Logging and testing omitted)

# Layer with NACLs and WAF for defense in depth
# (NACL and WAF configuration omitted)