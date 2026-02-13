# Create a CloudWatch Logs metric filter and alarm for VPC changes
resource "aws_cloudwatch_log_metric_filter" "remediation_vpc_changes_filter" {
  name = "vpc-changes-filter"
  pattern        = "{$.eventName = CreateVpc} || {$.eventName = DeleteVpc} || {$.eventName = ModifyVpcAttribute} || {$.eventName = AcceptVpcPeeringConnection} || {$.eventName = CreateVpcPeeringConnection} || {$.eventName = DeleteVpcPeeringConnection} || {$.eventName = RejectVpcPeeringConnection}"
  log_group_name = data.aws_cloudwatch_log_group.existing_log_group.name

  metric_transformation {
    name = "VPCChanges"
    namespace = "VPCChanges"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "remediation_vpc_changes_alarm" {
  alarm_name          = "vpc-changes-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = aws_cloudwatch_log_metric_filter.remediation_vpc_changes_filter.name
  namespace           = "VPCChanges"
  period              = 60
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Alarm when VPC changes occur"
  alarm_actions       = [data.aws_sns_topic.existing_topic.arn]
}

# Reference the existing CloudWatch Log Group and SNS Topic
data "aws_cloudwatch_log_group" "existing_log_group" {
  name = "132410971304"
}

data "aws_sns_topic" "existing_topic" {
  name = "my-sns-topic"
}