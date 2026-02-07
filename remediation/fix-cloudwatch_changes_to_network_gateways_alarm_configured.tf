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
    namespace = "SecurityLogs"
    value     = "1"
  }
}

# Create a CloudWatch alarm for the network gateway changes metric filter
resource "aws_cloudwatch_metric_alarm" "network_gateway_changes_alarm" {
  alarm_name          = "NetworkGatewayChangesAlarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "NetworkGatewayChanges"
  namespace           = "SecurityLogs"
  period              = "60"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Alarm when changes are made to network gateways"
  alarm_actions       = ["arn:aws:sns:ap-northeast-2:132410971304:your-sns-topic-arn"]
}


This Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Creates a CloudWatch Logs metric filter for the following network gateway events:
   - `CreateNetworkInterface`
   - `DeleteNetworkInterface`
   - `AttachNetworkInterface`
   - `DetachNetworkInterface`
   - `CreateNetworkInterfacePermission`
   - `DeleteNetworkInterfacePermission`
3. Creates a CloudWatch alarm that triggers when the network gateway changes metric filter detects any changes, and sends an alert to the specified SNS topic.