# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Create a CloudWatch Logs metric filter for changes to network gateways
resource "aws_cloudwatch_log_metric_filter" "network_gateway_changes" {
  name           = "NetworkGatewayChanges"
  pattern        = "{$.eventName = CreateNetworkInterface} || {$.eventName = DeleteNetworkInterface} || {$.eventName = AttachNetworkInterface} || {$.eventName = DetachNetworkInterface} || {$.eventName = CreateNetworkInterfacePermission} || {$.eventName = DeleteNetworkInterfacePermission}"
  log_group_name = "arn:aws:logs:ap-northeast-2:132410971304:log-group"

  metric_transformation {
    name      = "NetworkGatewayChanges"
    namespace = "SecurityMetrics"
    value     = "1"
  }
}

# Create a CloudWatch alarm for the network gateway changes metric filter
resource "aws_cloudwatch_metric_alarm" "network_gateway_changes_alarm" {
  alarm_name          = "NetworkGatewayChangesAlarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "NetworkGatewayChanges"
  namespace           = "SecurityMetrics"
  period              = "60"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Alarm when changes are made to network gateways"
  alarm_actions       = ["arn:aws:sns:ap-northeast-2:132410971304:NetworkGatewayChangesAlert"]
}


This Terraform code creates a CloudWatch Logs metric filter and an alarm for changes to network gateways. The metric filter looks for specific CloudTrail event names related to network gateway modifications, and the alarm is triggered when the metric value is greater than or equal to 1. The alarm action is set to an SNS topic, which can be used to notify responders of the detected changes.