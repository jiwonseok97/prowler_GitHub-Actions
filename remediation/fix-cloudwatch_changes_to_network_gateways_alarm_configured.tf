# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Create a CloudWatch Logs metric filter for changes to network gateways
resource "aws_cloudwatch_log_metric_filter" "network_gateway_changes" {
  name           = "NetworkGatewayChanges"
  pattern        = "{$.eventName = CreateNetworkInterface} || {$.eventName = DeleteNetworkInterface} || {$.eventName = AttachNetworkInterface} || {$.eventName = DetachNetworkInterface} || {$.eventName = CreateNetworkAcl} || {$.eventName = DeleteNetworkAcl} || {$.eventName = CreateNetworkAclEntry} || {$.eventName = DeleteNetworkAclEntry} || {$.eventName = ReplaceNetworkAclEntry} || {$.eventName = CreateSecurityGroup} || {$.eventName = DeleteSecurityGroup} || {$.eventName = AuthorizeSecurityGroupIngress} || {$.eventName = AuthorizeSecurityGroupEgress} || {$.eventName = RevokeSecurityGroupIngress} || {$.eventName = RevokeSecurityGroupEgress} || {$.eventName = CreateCustomerGateway} || {$.eventName = DeleteCustomerGateway} || {$.eventName = AttachInternetGateway} || {$.eventName = DetachInternetGateway} || {$.eventName = CreateVpnConnection} || {$.eventName = DeleteVpnConnection} || {$.eventName = CreateVpnGateway} || {$.eventName = DeleteVpnGateway} || {$.eventName = AttachVpnGateway} || {$.eventName = DetachVpnGateway}"
  log_group_name = "arn:aws:logs:ap-northeast-2:132410971304:log-group"
  metric_transformation {
    name      = "NetworkGatewayChanges"
    namespace = "CloudTrailMetrics"
    value     = "1"
  }
}

# Create a CloudWatch alarm for the network gateway changes metric filter
resource "aws_cloudwatch_metric_alarm" "network_gateway_changes_alarm" {
  alarm_name          = "NetworkGatewayChangesAlarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "NetworkGatewayChanges"
  namespace           = "CloudTrailMetrics"
  period              = "60"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Alarm when changes are made to network gateways"
  alarm_actions       = ["arn:aws:sns:ap-northeast-2:132410971304:my-alarm-topic"]
}


This Terraform code does the following:

1. Configures the AWS provider for the ap-northeast-2 region.
2. Creates a CloudWatch Logs metric filter that captures various events related to changes in network gateways, such as creating, deleting, attaching, and detaching network interfaces, network ACLs, security groups, customer gateways, VPN connections, and VPN gateways.
3. Creates a CloudWatch alarm that triggers when the "NetworkGatewayChanges" metric filter detects at least one event, and sends an alarm notification to the "my-alarm-topic" SNS topic.