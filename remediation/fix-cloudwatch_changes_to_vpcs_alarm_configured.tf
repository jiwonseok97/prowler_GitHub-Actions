# Create a CloudWatch Logs metric filter and alarm for VPC changes
resource "aws_cloudwatch_log_metric_filter" "remediation_vpc_changes_filter" {
  name = "remediation-vpc-changes-filter"
  pattern        = "{$.eventName = CreateVpc} || {$.eventName = DeleteVpc} || {$.eventName = ModifyVpcAttribute} || {$.eventName = AcceptVpcPeeringConnection} || {$.eventName = CreateVpcPeeringConnection} || {$.eventName = DeleteVpcPeeringConnection} || {$.eventName = RejectVpcPeeringConnection}"
  log_group_name = "132410971304"

  metric_transformation {
    name = "VPCChanges"
    namespace = "VPCChanges"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "remediation_vpc_changes_alarm" {
  alarm_name          = "remediation-vpc-changes-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "VPCChanges"
  namespace           = "VPCChanges"
  period              = "60"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Alarm when any VPC changes occur"
  alarm_actions       = [data.aws_sns_topic.remediation_topic.arn]
}

data "aws_sns_topic" "remediation_topic" {
  name = "remediation-topic"
}