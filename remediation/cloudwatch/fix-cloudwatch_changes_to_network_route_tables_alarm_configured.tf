# Create a CloudWatch Logs metric filter and alarm to monitor VPC route table changes
resource "aws_cloudwatch_log_metric_filter" "remediation_vpc_route_table_changes" {
  name           = "remediation-vpc-route-table-changes"
  pattern        = "{$.eventName = CreateRoute} || {$.eventName = CreateRouteTable} || {$.eventName = ReplaceRoute} || {$.eventName = ReplaceRouteTableAssociation} || {$.eventName = DeleteRouteTable} || {$.eventName = DeleteRoute} || {$.eventName = AssociateRouteTable} || {$.eventName = DisassociateRouteTable}"
  log_group_name = "132410971304"

  metric_transformation {
    name      = "VPCRouteTableChanges"
    namespace = "MyApp/CloudTrail"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "remediation_vpc_route_table_changes_alarm" {
  alarm_name          = "remediation-vpc-route-table-changes-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = aws_cloudwatch_log_metric_filter.remediation_vpc_route_table_changes.name
  namespace           = "MyApp/CloudTrail"
  period              = "60"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Alarm when VPC route table changes occur"
  alarm_actions       = [data.aws_sns_topic.remediation_alarm_topic.arn]
}

# Reference an existing SNS topic to receive the alarm notifications
data "aws_sns_topic" "remediation_alarm_topic" {
  name = "remediation-alarm-topic"
}
