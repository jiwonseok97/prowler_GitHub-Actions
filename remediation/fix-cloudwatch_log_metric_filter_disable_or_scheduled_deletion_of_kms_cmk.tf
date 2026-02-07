# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Create a CloudWatch log metric filter for the "DisableKey" event
resource "aws_cloudwatch_log_metric_filter" "disable_kms_key" {
  name           = "DisableKMSKey"
  pattern        = "{$.eventName = DisableKey}"
  log_group_name = "arn:aws:logs:ap-northeast-2:132410971304:log-group"

  metric_transformation {
    name      = "DisabledKMSKeys"
    namespace = "KMSKeyState"
    value     = "1"
  }
}

# Create a CloudWatch alarm for the "DisableKey" metric filter
resource "aws_cloudwatch_metric_alarm" "disable_kms_key_alarm" {
  alarm_name          = "DisableKMSKeyAlarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "DisabledKMSKeys"
  namespace           = "KMSKeyState"
  period              = "60"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Alarm when a customer-managed KMS key is disabled"
  alarm_actions       = ["arn:aws:sns:ap-northeast-2:132410971304:your-sns-topic-arn"]
}

# Create a CloudWatch log metric filter for the "ScheduleKeyDeletion" event
resource "aws_cloudwatch_log_metric_filter" "schedule_kms_key_deletion" {
  name           = "ScheduleKMSKeyDeletion"
  pattern        = "{$.eventName = ScheduleKeyDeletion}"
  log_group_name = "arn:aws:logs:ap-northeast-2:132410971304:log-group"

  metric_transformation {
    name      = "ScheduledKMSKeyDeletions"
    namespace = "KMSKeyState"
    value     = "1"
  }
}

# Create a CloudWatch alarm for the "ScheduleKeyDeletion" metric filter
resource "aws_cloudwatch_metric_alarm" "schedule_kms_key_deletion_alarm" {
  alarm_name          = "ScheduleKMSKeyDeletionAlarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "ScheduledKMSKeyDeletions"
  namespace           = "KMSKeyState"
  period              = "60"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Alarm when a customer-managed KMS key is scheduled for deletion"
  alarm_actions       = ["arn:aws:sns:ap-northeast-2:132410971304:your-sns-topic-arn"]
}


This Terraform code creates the following resources:

1. A CloudWatch log metric filter for the "DisableKey" event, which tracks when a customer-managed KMS key is disabled.
2. A CloudWatch alarm that triggers when the "DisableKey" metric filter detects a disabled KMS key.
3. A CloudWatch log metric filter for the "ScheduleKeyDeletion" event, which tracks when a customer-managed KMS key is scheduled for deletion.
4. A CloudWatch alarm that triggers when the "ScheduleKeyDeletion" metric filter detects a scheduled KMS key deletion.

The alarms are configured to send notifications to an SNS topic, which you'll need to replace with the appropriate ARN for your own SNS topic.