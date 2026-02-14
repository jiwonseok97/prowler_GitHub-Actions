# Create a CloudWatch Logs metric filter and alarm to monitor VPC route table changes
resource "aws_cloudwatch_log_metric_filter" "remediation_route_table_changes_filter" {
  name = "remediation-route-table-changes-filter"
  pattern        = "{$.eventName = CreateRoute} || {$.eventName = CreateRouteTable} || {$.eventName = ReplaceRoute} || {$.eventName = ReplaceRouteTableAssociation} || {$.eventName = DeleteRouteTable} || {$.eventName = DeleteRoute} || {$.eventName = AssociateRouteTable} || {$.eventName = DisassociateRouteTable}"
  log_group_name = "132410971304"

  metric_transformation {
    name = "RouteTableChanges"
    namespace = "MyApp/CloudTrail"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "remediation_route_table_changes_alarm" {
  alarm_name          = "remediation-route-table-changes-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = aws_cloudwatch_log_metric_filter.remediation_route_table_changes_filter.name
  namespace           = "MyApp/CloudTrail"
  period              = "60"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Alarm when a VPC route table is created, modified, or deleted"
  alarm_actions       = [data.aws_sns_topic.remediation_sns_topic.arn]
}

# Use a data source to reference an existing SNS topic for alarm notifications
data "aws_sns_topic" "remediation_sns_topic" {
  name = "remediation-notifications"
}