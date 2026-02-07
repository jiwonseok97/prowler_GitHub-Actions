# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Create a CloudWatch Logs metric filter for security group changes
resource "aws_cloudwatch_log_metric_filter" "security_group_changes" {
  name           = "security-group-changes"
  pattern        = "{$.eventName = AuthorizeSecurityGroupIngress} || {$.eventName = AuthorizeSecurityGroupEgress} || {$.eventName = RevokeSecurityGroupIngress} || {$.eventName = RevokeSecurityGroupEgress} || {$.eventName = CreateSecurityGroup} || {$.eventName = DeleteSecurityGroup}"
  log_group_name = "arn:aws:logs:ap-northeast-2:132410971304:log-group"

  metric_transformation {
    name      = "SecurityGroupChanges"
    namespace = "SecurityAudit"
    value     = "1"
  }
}

# Create a CloudWatch alarm for security group changes
resource "aws_cloudwatch_metric_alarm" "security_group_changes_alarm" {
  alarm_name          = "security-group-changes-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "SecurityGroupChanges"
  namespace           = "SecurityAudit"
  period              = "60"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Alarm when there are changes to security groups"
  alarm_actions       = ["arn:aws:sns:ap-northeast-2:132410971304:security-group-changes-notification"]
}


This Terraform code does the following:

1. Configures the AWS provider for the ap-northeast-2 region.
2. Creates a CloudWatch Logs metric filter that captures security group changes, including authorization, revocation, creation, and deletion of security groups.
3. Creates a CloudWatch alarm that triggers when there is at least one security group change, and sends a notification to the "security-group-changes-notification" SNS topic.