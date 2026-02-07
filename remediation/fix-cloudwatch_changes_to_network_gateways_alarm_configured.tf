# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Create a CloudWatch Logs metric filter for changes to network gateways
resource "aws_cloudwatch_log_metric_filter" "network_gateway_changes" {
  name           = "NetworkGatewayChanges"
  pattern        = "{$.eventName = CreateNetworkInterface} || {$.eventName = DeleteNetworkInterface} || {$.eventName = AttachNetworkInterface} || {$.eventName = DetachNetworkInterface} || {$.eventName = CreateNetworkAcl} || {$.eventName = DeleteNetworkAcl} || {$.eventName = CreateNetworkAclEntry} || {$.eventName = DeleteNetworkAclEntry} || {$.eventName = ReplaceNetworkAclEntry} || {$.eventName = CreateSecurityGroup} || {$.eventName = DeleteSecurityGroup} || {$.eventName = AuthorizeSecurityGroupIngress} || {$.eventName = AuthorizeSecurityGroupEgress} || {$.eventName = RevokeSecurityGroupIngress} || {$.eventName = RevokeSecurityGroupEgress}"
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


This Terraform code creates a CloudWatch Logs metric filter for changes to network gateways and a CloudWatch alarm that triggers when the metric filter detects any changes. The alarm is configured to send notifications to an SNT topic, which you should replace with the appropriate ARN for your SNS topic.