# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Create a CloudWatch log metric filter for S3 bucket policy changes
resource "aws_cloudwatch_log_metric_filter" "s3_bucket_policy_changes" {
  name           = "S3BucketPolicyChanges"
  pattern        = "{$.eventSource = s3.amazonaws.com && $.eventName = PutBucketPolicy}"
  log_group_name = "arn:aws:logs:ap-northeast-2:132410971304:log-group"

  metric_transformation {
    name      = "S3BucketPolicyChanges"
    namespace = "MyApplication"
    value     = "1"
  }
}

# Create a CloudWatch alarm for the S3 bucket policy changes metric
resource "aws_cloudwatch_metric_alarm" "s3_bucket_policy_changes_alarm" {
  alarm_name          = "S3BucketPolicyChangesAlarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = aws_cloudwatch_log_metric_filter.s3_bucket_policy_changes.metric_transformation[0].name
  namespace           = aws_cloudwatch_log_metric_filter.s3_bucket_policy_changes.metric_transformation[0].namespace
  period              = "60"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Alarm when S3 bucket policy changes are detected"
  alarm_actions       = ["arn:aws:sns:ap-northeast-2:132410971304:my-alarm-topic"]
}


This Terraform code creates a CloudWatch log metric filter and an alarm for S3 bucket policy changes. The metric filter looks for the `PutBucketPolicy` event in the specified log group, and the alarm is triggered when the metric value is greater than or equal to 1. The alarm action is set to an SNS topic, which can be used to notify the appropriate team or integrate with a SIEM system.