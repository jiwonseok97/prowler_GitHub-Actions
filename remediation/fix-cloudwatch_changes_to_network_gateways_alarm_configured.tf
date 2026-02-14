# Create a CloudWatch Logs metric filter and alarm for changes to network gateways
resource "aws_cloudwatch_log_metric_filter" "remediation_network_gateway_changes" {
  name = "remediation-network-gateway-changes"
  pattern        = "{$.eventName = CreateCustomerGateway} || {$.eventName = DeleteCustomerGateway} || {$.eventName = AttachInternetGateway} || {$.eventName = DetachInternetGateway} || {$.eventName = CreateInternetGateway} || {$.eventName = DeleteInternetGateway} || {$.eventName = CreateVpnGateway} || {$.eventName = DeleteVpnGateway} || {$.eventName = AttachVpnGateway} || {$.eventName = DetachVpnGateway}"
  log_group_name = "YOUR_LOG_GROUP_NAME"

  metric_transformation {
    name = "NetworkGatewayChanges"
    namespace = "CISBenchmark"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "remediation_network_gateway_changes_alarm" {
  alarm_name          = "remediation-network-gateway-changes-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods   = 1
  metric_name         = "NetworkGatewayChanges"
  namespace           = "CISBenchmark"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Alarm when network gateway changes occur"
  alarm_actions       = [data.aws_sns_topic.remediation_topic.arn]
}

# Retrieve the existing SNS topic ARN
data "aws_sns_topic" "remediation_topic" {
  name = "remediation-topic"
}