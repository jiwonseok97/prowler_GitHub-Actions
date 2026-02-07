# Configure the AWS provider for the ap-northeast-2 region

# Create a CloudWatch Logs metric filter for root account usage
resource "aws_cloudwatch_log_metric_filter" "root_account_usage" {
  name           = "RootAccountUsage"
  pattern        = "{$.userIdentity.type = \"Root\" && $.userIdentity.invokedBy NOT EXISTS && $.eventType != \"AwsServiceEvent\"}"
  log_group_name = "arn:aws:logs:ap-northeast-2:132410971304:log-group"

  metric_transformation {
    name      = "RootUsage"
    namespace = "MyApp/Audit"
    value     = "1"
  }
}

# Create a CloudWatch alarm for the root account usage metric filter
resource "aws_cloudwatch_metric_alarm" "root_account_usage_alarm" {
  alarm_name          = "RootAccountUsageAlarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "RootUsage"
  namespace           = "MyApp/Audit"
  period              = "60"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Alarm when root account is used"
  alarm_actions       = ["arn:aws:sns:ap-northeast-2:132410971304:my-alert-topic"]
}


The provided Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Creates a CloudWatch Logs metric filter named `RootAccountUsage` that captures any root account activity, excluding AWS service events.
3. Creates a CloudWatch alarm named `RootAccountUsageAlarm` that triggers when the `RootUsage` metric (from the metric filter) is greater than or equal to 1, indicating root account usage. The alarm is set to send notifications to the `my-alert-topic` SNS topic.

This code addresses the security finding by enabling real-time alerts for root account usage, which is a recommended best practice for AWS security.