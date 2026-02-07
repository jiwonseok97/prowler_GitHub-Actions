# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Create a CloudWatch Logs metric filter for VPC changes
resource "aws_cloudwatch_log_metric_filter" "vpc_changes" {
  name           = "vpc-changes"
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
  alarm_name          = "vpc-changes-alarm"
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


This Terraform code does the following:

1. Configures the AWS provider for the ap-northeast-2 region.
2. Creates a CloudWatch Logs metric filter that captures various VPC change events, such as creating, deleting, or modifying VPCs, VPC peering connections, and VPC classic link.
3. Creates a CloudWatch alarm that triggers when the VPC changes metric filter detects at least one event, and sends a notification to the "my-alarm-topic" SNS topic.