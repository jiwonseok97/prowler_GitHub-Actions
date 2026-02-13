# Create a CloudWatch Logs metric filter for AWS Organizations changes
resource "aws_cloudwatch_log_metric_filter" "remediation_organizations_changes" {
  name = "organizations-changes"
  pattern        = "{$.eventSource = organizations.amazonaws.com}"
  log_group_name = "132410971304"

  metric_transformation {
    name = "OrganizationsChanges"
    namespace = "MyApp/Audit"
    value     = "1"
  }
}

# Create a CloudWatch Alarm for the Organizations changes metric
resource "aws_cloudwatch_metric_alarm" "remediation_organizations_changes_alarm" {
  alarm_name          = "organizations-changes-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = aws_cloudwatch_log_metric_filter.remediation_organizations_changes.metric_transformation[0].name
  namespace           = aws_cloudwatch_log_metric_filter.remediation_organizations_changes.metric_transformation[0].namespace
  period              = 60
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Alarm when AWS Organizations changes are detected"
  alarm_actions       = [data.aws_sns_topic.remediation_sns_topic.arn]
}

# Use a data source to reference an existing SNS topic for the alarm
data "aws_sns_topic" "remediation_sns_topic" {
  name = "my-remediation-topic"
}