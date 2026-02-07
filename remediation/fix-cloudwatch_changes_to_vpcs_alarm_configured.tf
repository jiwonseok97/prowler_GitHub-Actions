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
    namespace = "MyApp/VPCChanges"
    value     = "1"
  }
}

# Create a CloudWatch alarm for the VPC changes metric filter
resource "aws_cloudwatch_metric_alarm" "vpc_changes_alarm" {
  alarm_name          = "vpc-changes-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "VPCChanges"
  namespace           = "MyApp/VPCChanges"
  period              = "60"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Alarm when there are changes to VPC resources"
  alarm_actions       = ["arn:aws:sns:ap-northeast-2:132410971304:my-alarm-topic"]
}


The provided Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Creates a CloudWatch Logs metric filter named `vpc-changes` that monitors for various VPC-related events, such as creating, deleting, or modifying VPCs, VPC peering connections, and VPC classic link.
3. Creates a CloudWatch alarm named `vpc-changes-alarm` that triggers when the `VPCChanges` metric (defined in the metric filter) is greater than or equal to 1, indicating that a VPC change event has occurred.
4. The alarm action is set to an SNS topic `arn:aws:sns:ap-northeast-2:132410971304:my-alarm-topic`, which can be used to notify responders of the VPC change event.