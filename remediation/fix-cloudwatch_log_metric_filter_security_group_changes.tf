# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Create a CloudWatch Logs metric filter for security group changes
resource "aws_cloudwatch_log_metric_filter" "security_group_changes" {
  name           = "security-group-changes"
  pattern        = "{$.eventName = AuthorizeSecurityGroupIngress} || {$.eventName = AuthorizeSecurityGroupEgress} || {$.eventName = RevokeSecurityGroupIngress} || {$.eventName = RevokeSecurityGroupEgress} || {$.eventName = CreateSecurityGroup} || {$.eventName = DeleteSecurityGroup}"
  log_group_name = "YOUR_CLOUDTRAIL_LOG_GROUP_NAME"

  metric_transformation {
    name      = "SecurityGroupChanges"
    namespace = "SecurityChanges"
    value     = "1"
  }
}

# Create a CloudWatch alarm for the security group changes metric filter
resource "aws_cloudwatch_metric_alarm" "security_group_changes_alarm" {
  alarm_name          = "security-group-changes-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "SecurityGroupChanges"
  namespace           = "SecurityChanges"
  period              = "60"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Alarm when there are changes to security groups"
  alarm_actions       = ["arn:aws:sns:ap-northeast-2:YOUR_ACCOUNT_ID:YOUR_SNS_TOPIC_NAME"]
}


This Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Creates a CloudWatch Logs metric filter for security group changes, which monitors the CloudTrail logs for specific security group-related events.
3. Creates a CloudWatch alarm that triggers when the security group changes metric filter detects any changes, and sends an alert to the specified SNS topic.

Note: You will need to replace `YOUR_CLOUDTRAIL_LOG_GROUP_NAME` with the name of your CloudTrail log group, and `YOUR_ACCOUNT_ID` and `YOUR_SNS_TOPIC_NAME` with the appropriate values for your AWS environment.