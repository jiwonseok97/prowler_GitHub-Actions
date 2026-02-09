# Create a data source to look up the existing CloudWatch Logs log group
data "aws_cloudwatch_log_group" "existing_log_group" {
  name = "arn:aws:logs:ap-northeast-2:132410971304:log-group"
}

# Create a CloudWatch Logs metric filter and alarm to monitor VPC route table changes
resource "aws_cloudwatch_log_metric_filter" "remediation_route_table_changes" {
  name           = "remediation_route_table_changes"
  pattern        = "{$.eventName = CreateRoute | $.eventName = CreateRouteTable | $.eventName = ReplaceRoute | $.eventName = ReplaceRouteTableAssociation | $.eventName = DeleteRouteTable | $.eventName = DeleteRoute | $.eventName = DisassociateRouteTable}"
  log_group_name = data.aws_cloudwatch_log_group.existing_log_group.name

  metric_transformation {
    name      = "RouteTableChanges"
    namespace = "MyApp/SecurityMetrics"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "remediation_route_table_changes_alarm" {
  alarm_name          = "remediation_route_table_changes_alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "RouteTableChanges"
  namespace           = "MyApp/SecurityMetrics"
  period              = "60"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Alarm when a VPC route table change is detected"
  alarm_actions       = ["arn:aws:sns:ap-northeast-2:132410971304:my-security-topic"]
}

# Configure the AWS provider for the ap-northeast-2 region