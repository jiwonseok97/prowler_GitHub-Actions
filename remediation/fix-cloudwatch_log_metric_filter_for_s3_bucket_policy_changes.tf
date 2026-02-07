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
    namespace = "MyApp/SecurityLogs"
    value     = "1"
  }
}

# Create a CloudWatch alarm for the S3 bucket policy changes metric filter
resource "aws_cloudwatch_metric_alarm" "s3_bucket_policy_changes_alarm" {
  alarm_name          = "S3BucketPolicyChangesAlarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "S3BucketPolicyChanges"
  namespace           = "MyApp/SecurityLogs"
  period              = "60"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Alarm when S3 bucket policy changes are detected"
  alarm_actions       = ["arn:aws:sns:ap-northeast-2:132410971304:my-security-topic"]
}


This Terraform code does the following:

1. Configures the AWS provider for the ap-northeast-2 region.
2. Creates a CloudWatch log metric filter for S3 bucket policy changes. The filter looks for events with the `eventSource` of `s3.amazonaws.com` and the `eventName` of `PutBucketPolicy`.
3. Creates a CloudWatch alarm for the S3 bucket policy changes metric filter. The alarm is triggered when the metric value is greater than or equal to 1, indicating that a bucket policy change has been detected. The alarm action is to send a notification to the `my-security-topic` SNS topic.