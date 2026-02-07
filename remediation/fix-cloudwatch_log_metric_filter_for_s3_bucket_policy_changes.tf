# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Create a CloudWatch log metric filter for S3 bucket policy changes
resource "aws_cloudwatch_log_metric_filter" "s3_bucket_policy_changes" {
  name           = "s3-bucket-policy-changes"
  pattern        = "{$.eventSource = s3.amazonaws.com && $.eventName = PutBucketPolicy}"
  log_group_name = "arn:aws:logs:ap-northeast-2:132410971304:log-group"

  metric_transformation {
    name      = "S3BucketPolicyChanges"
    namespace = "MyApp/SecurityLogs"
    value     = "1"
  }
}

# Create a CloudWatch alarm for S3 bucket policy changes
resource "aws_cloudwatch_metric_alarm" "s3_bucket_policy_changes_alarm" {
  alarm_name          = "s3-bucket-policy-changes-alarm"
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


The provided Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Creates a CloudWatch log metric filter for S3 bucket policy changes. The filter looks for events with the `eventSource` of `s3.amazonaws.com` and the `eventName` of `PutBucketPolicy`.
3. Creates a CloudWatch alarm for the S3 bucket policy changes metric. The alarm is triggered when the metric value is greater than or equal to 1, indicating that a policy change has occurred. The alarm action is set to an SNS topic named `my-security-topic`.

This code addresses the security finding by establishing a metric filter and alarm to detect and alert on S3 bucket policy changes, as recommended in the finding.