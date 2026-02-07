# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Create a CloudWatch log metric filter for S3 bucket policy changes
resource "aws_cloudwatch_log_metric_filter" "s3_bucket_policy_changes" {
  name           = "s3-bucket-policy-changes"
  pattern        = "{$.eventName = PutBucketPolicy}"
  log_group_name = "arn:aws:logs:ap-northeast-2:132410971304:log-group"

  metric_transformation {
    name      = "S3BucketPolicyChanges"
    namespace = "MyApp/SecurityLogs"
    value     = "1"
  }
}

# Create a CloudWatch alarm for the S3 bucket policy changes metric
resource "aws_cloudwatch_metric_alarm" "s3_bucket_policy_changes_alarm" {
  alarm_name          = "s3-bucket-policy-changes-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "S3BucketPolicyChanges"
  namespace           = "MyApp/SecurityLogs"
  period              = "60"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Alarm when an S3 bucket policy is changed"
  alarm_actions       = ["arn:aws:sns:ap-northeast-2:132410971304:my-security-topic"]
}


This Terraform code creates a CloudWatch log metric filter and an alarm for S3 bucket policy changes. The metric filter looks for the `PutBucketPolicy` event name in the CloudWatch log group specified by the `log_group_name` argument. The metric filter then creates a custom metric called `S3BucketPolicyChanges` in the `MyApp/SecurityLogs` namespace.

The CloudWatch alarm is then created to monitor the `S3BucketPolicyChanges` metric. The alarm is configured to trigger when the metric value is greater than or equal to 1, indicating that an S3 bucket policy change has occurred. The alarm action is set to send a notification to an SNS topic with the ARN `arn:aws:sns:ap-northeast-2:132410971304:my-security-topic`.