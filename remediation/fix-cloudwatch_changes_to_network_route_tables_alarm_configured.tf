# Create a CloudWatch Logs metric filter to capture VPC route table changes
resource "aws_cloudwatch_log_metric_filter" "remediation_vpc_route_table_changes" {
  name           = "remediation-vpc-route-table-changes"
  pattern        = "{$.eventName = CreateRoute} || {$.eventName = CreateRouteTable} || {$.eventName = ReplaceRoute} || {$.eventName = ReplaceRouteTableAssociation} || {$.eventName = DeleteRouteTable} || {$.eventName = DeleteRoute} || {$.eventName = AssociateRouteTable} || {$.eventName = DisassociateRouteTable}"
  log_group_name = data.aws_cloudwatch_log_group.existing_log_group.name

  metric_transformation {
    name      = "VPCRouteTableChanges"
    namespace = "MyApp/SecurityLogs"
    value     = "1"
  }
}

data "aws_cloudwatch_log_group" "existing_log_group" {
  name = "arn:aws:logs:ap-northeast-2:132410971304:log-group"
}

# Create a CloudWatch alarm to trigger on VPC route table changes
resource "aws_cloudwatch_metric_alarm" "remediation_vpc_route_table_changes_alarm" {
  alarm_name          = "remediation-vpc-route-table-changes-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "VPCRouteTableChanges"
  namespace           = "MyApp/SecurityLogs"
  period              = "60"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Alarm when VPC route table changes occur"
  alarm_actions       = [aws_sns_topic.remediation_security_notifications.arn]
}

resource "aws_sns_topic" "remediation_security_notifications" {
  name = "my-security-notifications"
}