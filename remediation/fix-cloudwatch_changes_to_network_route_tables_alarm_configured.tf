# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Create a CloudWatch Logs metric filter to monitor VPC route table changes
resource "aws_cloudwatch_log_metric_filter" "vpc_route_table_changes" {
  name           = "vpc-route-table-changes"
  pattern        = "{$.eventName = CreateRoute} || {$.eventName = CreateRouteTable} || {$.eventName = ReplaceRoute} || {$.eventName = ReplaceRouteTableAssociation} || {$.eventName = DeleteRouteTable} || {$.eventName = DeleteRoute} || {$.eventName = AssociateRouteTable} || {$.eventName = DisassociateRouteTable}"
  log_group_name = "arn:aws:logs:ap-northeast-2:132410971304:log-group"

  metric_transformation {
    name      = "VPCRouteTableChanges"
    namespace = "SecurityMetrics"
    value     = "1"
  }
}

# Create a CloudWatch alarm to trigger when VPC route table changes are detected
resource "aws_cloudwatch_metric_alarm" "vpc_route_table_changes_alarm" {
  alarm_name          = "vpc-route-table-changes-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "VPCRouteTableChanges"
  namespace           = "SecurityMetrics"
  period              = "60"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Alarm when VPC route table changes are detected"
  alarm_actions       = ["arn:aws:sns:ap-northeast-2:132410971304:your-sns-topic-arn"]
}


The provided Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Creates a CloudWatch Logs metric filter to monitor VPC route table changes. The filter looks for specific event names related to route table modifications.
3. Creates a CloudWatch alarm that triggers when the "VPCRouteTableChanges" metric, captured by the metric filter, is greater than or equal to 1. This will alert when any VPC route table changes are detected.
4. The alarm action is set to an SNS topic, which you will need to replace with the ARN of your own SNS topic to receive notifications.