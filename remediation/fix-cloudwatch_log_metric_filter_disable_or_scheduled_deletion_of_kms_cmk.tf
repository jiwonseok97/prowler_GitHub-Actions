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
  alarm_actions       = ["arn:aws:sns:ap-northeast-2:132410971304:my-alarm-topic"]
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
  alarm_actions       = ["arn:aws:sns:ap-northeast-2:132410971304:my-alarm-topic"]
}


The provided Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Creates a CloudWatch log metric filter for the `DisableKey` event, which tracks the number of disabled customer-managed KMS keys.
3. Creates a CloudWatch alarm for the `DisableKey` metric filter, which triggers an alarm when a customer-managed KMS key is disabled.
4. Creates a CloudWatch log metric filter for the `ScheduleKeyDeletion` event, which tracks the number of customer-managed KMS keys scheduled for deletion.
5. Creates a CloudWatch alarm for the `ScheduleKeyDeletion` metric filter, which triggers an alarm when a customer-managed KMS key is scheduled for deletion.

The alarms are configured to send notifications to the `arn:aws:sns:ap-northeast-2:132410971304:my-alarm-topic` SNS topic, which should be replaced with the appropriate SNS topic ARN for your environment.