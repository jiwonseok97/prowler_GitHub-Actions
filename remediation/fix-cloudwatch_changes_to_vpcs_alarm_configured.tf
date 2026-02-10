# Create a CloudWatch Logs metric filter to capture VPC changes
resource "aws_cloudwatch_log_metric_filter" "remediation_vpc_changes_filter" {
  name           = "vpc-changes-filter"
  pattern        = "{$.eventSource = ec2.amazonaws.com && ($.eventName = CreateVpc || $.eventName = DeleteVpc || $.eventName = ModifyVpcAttribute || $.eventName = AcceptVpcPeeringConnection || $.eventName = CreateVpcPeeringConnection || $.eventName = DeleteVpcPeeringConnection || $.eventName = RejectVpcPeeringConnection)}"
  log_group_name = data.aws_cloudwatch_log_group.existing_log_group.name

  metric_transformation {
    name      = "VPCChanges"
    namespace = "MyApp/VPCChanges"
    value     = "1"
  }
}

data "aws_cloudwatch_log_group" "existing_log_group" {
  name = "arn:aws:logs:ap-northeast-2:132410971304:log-group"
}

# Create a CloudWatch alarm to trigger on VPC changes
resource "aws_cloudwatch_metric_alarm" "remediation_vpc_changes_alarm" {
  alarm_name          = "vpc-changes-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "VPCChanges"
  namespace           = "MyApp/VPCChanges"
  period              = 60
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Alarm when VPC changes occur"
  alarm_actions       = [aws_sns_topic.remediation_alarm_topic.arn]
}

resource "aws_sns_topic" "remediation_alarm_topic" {
  name = "my-alarm-topic"
}