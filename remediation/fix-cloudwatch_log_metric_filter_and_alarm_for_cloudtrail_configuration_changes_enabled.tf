# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Create a CloudWatch Logs metric filter for CloudTrail configuration changes
resource "aws_cloudwatch_log_metric_filter" "cloudtrail_configuration_changes" {
  name           = "CloudTrailConfigurationChanges"
  pattern        = "{$.eventName = CreateTrail} || {$.eventName = UpdateTrail} || {$.eventName = DeleteTrail} || {$.eventName = StartLogging} || {$.eventName = StopLogging}"
  log_group_name = "arn:aws:logs:ap-northeast-2:132410971304:log-group"

  metric_transformation {
    name      = "CloudTrailConfigurationChanges"
    namespace = "CloudTrailConfigurationChanges"
    value     = "1"
  }
}

# Create a CloudWatch alarm for the CloudTrail configuration changes metric filter
resource "aws_cloudwatch_metric_alarm" "cloudtrail_configuration_changes_alarm" {
  alarm_name          = "CloudTrailConfigurationChangesAlarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_total_periods = 1
  evaluation_periods   = 1
  metric_name         = "CloudTrailConfigurationChanges"
  namespace           = "CloudTrailConfigurationChanges"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Alarm when CloudTrail configuration changes occur"
  alarm_actions       = ["arn:aws:sns:ap-northeast-2:132410971304:your-sns-topic-arn"]
}


This Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Creates a CloudWatch Logs metric filter for CloudTrail configuration changes, including events such as `CreateTrail`, `UpdateTrail`, `DeleteTrail`, `StartLogging`, and `StopLogging`.
3. Creates a CloudWatch alarm that triggers when the CloudTrail configuration changes metric filter detects at least one event. The alarm is configured to send a notification to the specified SNS topic.