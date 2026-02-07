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
2. Creates a CloudWatch Logs metric filter named `NACLChanges` that captures various NACL-related events from CloudTrail logs.
3. Creates a CloudWatch alarm named `NACLChangesAlarm` that triggers when the `NACLChanges` metric has a value greater than or equal to 1, indicating that a NACL change event has occurred.
4. The alarm is configured to send notifications to an SNR topic with the ARN `arn:aws:sns:ap-northeast-2:132410971304:your-sns-topic-arn`.

This code addresses the security finding by implementing a CloudWatch Logs metric filter and alarm for NACL change events, as recommended in the finding. It also includes the necessary provider configuration and references to existing resources.