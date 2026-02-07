# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Create a CloudWatch Logs metric filter to monitor VPC route table changes
resource "aws_cloudwatch_log_metric_filter" "route_table_changes" {
  name           = "VPCRouteTableChanges"
  pattern        = "{$.eventName = CreateRoute} || {$.eventName = CreateRouteTable} || {$.eventName = ReplaceRoute} || {$.eventName = ReplaceRouteTableAssociation} || {$.eventName = DeleteRouteTable} || {$.eventName = DeleteRoute} || {$.eventName = AssociateRouteTable} || {$.eventName = DisassociateRouteTable}"
  log_group_name = "arn:aws:logs:ap-northeast-2:132410971304:log-group"

  metric_transformation {
    name      = "VPCRouteTableChanges"
    namespace = "SecurityMetrics"
    value     = "1"
  }
}

# Create a CloudWatch alarm to trigger on VPC route table changes
resource "aws_cloudwatch_metric_alarm" "route_table_changes_alarm" {
  alarm_name          = "VPCRouteTableChangesAlarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "VPCRouteTableChanges"
  namespace           = "SecurityMetrics"
  period              = "60"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Alarm when VPC route table changes are detected"
  alarm_actions       = ["arn:aws:sns:ap-northeast-2:132410971304:my-security-topic"]
}


The provided Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Creates a CloudWatch Logs metric filter to monitor VPC route table changes. The filter looks for specific event names in the CloudTrail logs and increments a custom metric called `VPCRouteTableChanges` whenever a change is detected.
3. Creates a CloudWatch alarm that triggers when the `VPCRouteTableChanges` metric is greater than or equal to 1, indicating that a route table change has occurred. The alarm is configured to send a notification to an SNS topic with the ARN `arn:aws:sns:ap-northeast-2:132410971304:my-security-topic`.

This code addresses the security finding by implementing a CloudWatch Logs metric filter and alarm to monitor and alert on VPC route table changes, as recommended in the finding.