# Configure the AWS provider for the ap-northeast-2 region

# Create a CloudWatch Logs metric filter for security group changes
resource "aws_cloudwatch_log_metric_filter" "security_group_changes" {
  name           = "security-group-changes"
  pattern        = "{$.eventName = AuthorizeSecurityGroupIngress} || {$.eventName = AuthorizeSecurityGroupEgress} || {$.eventName = RevokeSecurityGroupIngress} || {$.eventName = RevokeSecurityGroupEgress} || {$.eventName = CreateSecurityGroup} || {$.eventName = DeleteSecurityGroup}"
  log_group_name = "YOUR_CLOUDTRAIL_LOG_GROUP_NAME"

  metric_transformation {
    name      = "SecurityGroupChanges"
    namespace = "MyApplication"
    value     = "1"
  }
}

# Create a CloudWatch alarm for the security group changes metric filter
resource "aws_cloudwatch_metric_alarm" "security_group_changes_alarm" {
  alarm_name          = "security-group-changes-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "SecurityGroupChanges"
  namespace           = "MyApplication"
  period              = "60"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Alarm when there are changes to security groups"
  alarm_actions       = ["arn:aws:sns:ap-northeast-2:132410971304:your-sns-topic-arn"]
}


# This Terraform code does the following:
# 
# 1. Configures the AWS provider for the `ap-northeast-2` region.
# 2. Creates a CloudWatch Logs metric filter for security group changes, using the provided pattern to match relevant events from CloudTrail logs.
# 3. Creates a CloudWatch alarm that triggers when the "SecurityGroupChanges" metric, as defined in the metric filter, is greater than or equal to 1. This will send an alert to the specified SNR topic.
# 
# Note: You will need to replace `YOUR_CLOUDTRAIL_LOG_GROUP_NAME` with the name of your CloudTrail log group, and `your-sns-topic-arn` with the ARN of the SNS topic you want to use for notifications.