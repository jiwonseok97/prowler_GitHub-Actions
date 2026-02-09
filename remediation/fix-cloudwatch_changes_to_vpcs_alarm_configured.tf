# Create a CloudWatch Logs metric filter to capture VPC changes
resource "aws_cloudwatch_log_metric_filter" "remediation_vpc_changes_metric_filter" {
  name           = "remediation-vpc-changes-metric-filter"
  pattern        = "{$.eventSource = ec2.amazonaws.com && ($.eventName = CreateVpc || $.eventName = DeleteVpc || $.eventName = ModifyVpcAttribute || $.eventName = AcceptVpcPeeringConnection || $.eventName = CreateVpcPeeringConnection || $.eventName = DeleteVpcPeeringConnection || $.eventName = RejectVpcPeeringConnection || $.eventName = AttachClassicLinkVpc || $.eventName = DetachClassicLinkVpc || $.eventName = DisableVpcClassicLink || $.eventName = EnableVpcClassicLink)}"
  log_group_name = "remediation-vpc-changes-log-group"

  metric_transformation {
    name      = "VPCChanges"
    namespace = "MyApp/VPCChanges"
    value     = "1"
  }
}

# Create a CloudWatch alarm to trigger on VPC changes
resource "aws_cloudwatch_metric_alarm" "remediation_vpc_changes_alarm" {
  alarm_name          = "remediation-vpc-changes-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = aws_cloudwatch_log_metric_filter.remediation_vpc_changes_metric_filter.metric_transformation[0].name
  namespace           = aws_cloudwatch_log_metric_filter.remediation_vpc_changes_metric_filter.metric_transformation[0].namespace
  period              = 60
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Alarm when VPC changes are detected"
  alarm_actions       = ["arn:aws:sns:ap-northeast-2:132410971304:remediation-vpc-changes-topic"]
}

# Create an SNS topic to receive the VPC changes alarm
resource "aws_sns_topic" "remediation_vpc_changes_topic" {
  name = "remediation-vpc-changes-topic"
}

# Create an SNS topic subscription to notify a target (e.g., email, Lambda)
resource "aws_sns_topic_subscription" "remediation_vpc_changes_topic_subscription" {
  topic_arn = aws_sns_topic.remediation_vpc_changes_topic.arn
  protocol  = "email"
  endpoint  = "example@example.com"
}