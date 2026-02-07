# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

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
2. Creates a CloudWatch Logs metric filter for root account usage. The filter pattern looks for log events where the user identity type is "Root", the invoked by field does not exist, and the event type is not an "AwsServiceEvent".
3. Creates a CloudWatch alarm for the root account usage metric filter. The alarm is triggered when the sum of the "RootUsage" metric is greater than or equal to 1 within a 1-minute period. When the alarm is triggered, it sends a notification to the "arn:aws:sns:ap-northeast-2:132410971304:my-alert-topic" SNR topic.