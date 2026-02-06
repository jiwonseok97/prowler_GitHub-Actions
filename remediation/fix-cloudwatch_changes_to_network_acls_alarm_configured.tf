# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Create a CloudWatch Logs metric filter for NACL change events
resource "aws_cloudwatch_log_metric_filter" "nacl_changes" {
  name           = "NACLChanges"
  pattern        = "{$.eventName = CreateNetworkAcl} || {$.eventName = CreateNetworkAclEntry} || {$.eventName = DeleteNetworkAcl} || {$.eventName = DeleteNetworkAclEntry} || {$.eventName = ReplaceNetworkAclEntry} || {$.eventName = ReplaceNetworkAcl}"
  log_group_name = "arn:aws:logs:ap-northeast-2:132410971304:log-group"

  metric_transformation {
    name      = "NACLChanges"
    namespace = "CloudTrailMetrics"
    value     = "1"
  }
}

# Create a CloudWatch alarm for the NACL change metric
resource "aws_cloudwatch_metric_alarm" "nacl_changes_alarm" {
  alarm_name          = "NACLChangesAlarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "NACLChanges"
  namespace           = "CloudTrailMetrics"
  period              = "60"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Alarm when there are changes to Network ACLs"
  alarm_actions       = ["arn:aws:sns:ap-northeast-2:132410971304:your-sns-topic-arn"]
}


This Terraform code does the following:

1. Configures the AWS provider for the ap-northeast-2 region.
2. Creates a CloudWatch Logs metric filter for NACL change events, including events such as CreateNetworkAcl, CreateNetworkAclEntry, DeleteNetworkAcl, DeleteNetworkAclEntry, ReplaceNetworkAclEntry, and ReplaceNetworkAcl.
3. Creates a CloudWatch alarm for the NACL change metric, which will trigger an alarm when the number of NACL changes is greater than or equal to 1. The alarm action is set to an SNS topic, which you should replace with the ARN of your own SNS topic.