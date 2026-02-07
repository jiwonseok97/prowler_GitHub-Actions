# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Create a CloudWatch Logs metric filter for VPC changes
resource "aws_cloudwatch_log_metric_filter" "vpc_changes" {
  name           = "VPCChanges"
  pattern        = "{$.eventName = CreateVpc} || {$.eventName = DeleteVpc} || {$.eventName = ModifyVpcAttribute} || {$.eventName = AcceptVpcPeeringConnection} || {$.eventName = CreateVpcPeeringConnection} || {$.eventName = DeleteVpcPeeringConnection} || {$.eventName = RejectVpcPeeringConnection} || {$.eventName = AttachClassicLinkVpc} || {$.eventName = DetachClassicLinkVpc} || {$.eventName = DisableVpcClassicLink} || {$.eventName = EnableVpcClassicLink}"
  log_group_name = "arn:aws:logs:ap-northeast-2:132410971304:log-group"

  metric_transformation {
    name      = "VPCChanges"
    namespace = "MyApp/Audit"
    value     = "1"
  }
}

# Create a CloudWatch alarm for the VPC changes metric filter
resource "aws_cloudwatch_metric_alarm" "vpc_changes_alarm" {
  alarm_name          = "VPCChangesAlarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "VPCChanges"
  namespace           = "MyApp/Audit"
  period              = "60"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Alarm when there are changes to VPC resources"
  alarm_actions       = ["arn:aws:sns:ap-northeast-2:132410971304:my-alarm-topic"]
}


The provided Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Creates a CloudWatch Logs metric filter named `VPCChanges` that monitors for various VPC-related events, such as creating, deleting, or modifying VPCs, VPC peering connections, and VPC classic link.
3. Creates a CloudWatch alarm named `VPCChangesAlarm` that triggers when the `VPCChanges` metric filter detects one or more events, and sends a notification to the `my-alarm-topic` SNS topic.

This code addresses the security finding by creating a CloudWatch Logs metric filter and alarm to monitor for critical VPC change events, which can help detect and respond to unauthorized modifications to the VPC infrastructure.