# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Create a CloudWatch Logs metric filter for NACL change events
resource "aws_cloudwatch_log_metric_filter" "nacl_changes" {
  name           = "NACLChanges"
  pattern        = "{$.eventName = CreateNetworkAcl} || {$.eventName = CreateNetworkAclEntry} || {$.eventName = DeleteNetworkAcl} || {$.eventName = DeleteNetworkAclEntry} || {$.eventName = ReplaceNetworkAclEntry} || {$.eventName = ReplaceNetworkAclAssociation}"
  log_group_name = "arn:aws:logs:ap-northeast-2:132410971304:log-group"

  metric_transformation {
    name      = "NACLChanges"
    namespace = "CloudTrailMetrics"
    value     = "1"
  }
}

# Create a CloudWatch alarm for the NACL changes metric filter
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


The provided Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Creates a CloudWatch Logs metric filter for NACL change events, including events such as creating, deleting, and replacing network ACLs and their entries.
3. Creates a CloudWatch alarm that triggers when the NACL changes metric filter detects at least one event in a 60-second period. The alarm action is set to an SNS topic, which you should replace with the ARN of your own SNS topic.

This code addresses the security finding by implementing a CloudWatch Logs metric filter and alarm for NACL change events, which can help you monitor and respond to changes in your network access control lists.