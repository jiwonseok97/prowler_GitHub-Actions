# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Get the existing CloudWatch Logs log group
data "aws_cloudwatch_log_group" "existing_log_group" {
  name = "arn:aws:logs:ap-northeast-2:132410971304:log-group"
}

# Create a CloudWatch Logs metric filter for AWS Organizations changes
resource "aws_cloudwatch_log_metric_filter" "organizations_changes" {
  name           = "organizations-changes"
  pattern        = "{$.eventSource = organizations.amazonaws.com}"
  log_group_name = data.aws_cloudwatch_log_group.existing_log_group.name

  metric_transformation {
    name      = "OrganizationsChanges"
    namespace = "MyApp/Audit"
    value     = "1"
  }
}

# Create a CloudWatch Alarm for the Organizations changes metric filter
resource "aws_cloudwatch_metric_alarm" "organizations_changes_alarm" {
  alarm_name          = "organizations-changes-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "OrganizationsChanges"
  namespace           = "MyApp/Audit"
  period              = "60"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Alarm when there are changes to AWS Organizations"
  alarm_actions       = ["arn:aws:sns:ap-northeast-2:132410971304:my-alert-topic"]
}


This Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Retrieves the existing CloudWatch Logs log group using the `data` source.
3. Creates a CloudWatch Logs metric filter for AWS Organizations changes, using the log group retrieved in the previous step.
4. Creates a CloudWatch Alarm for the Organizations changes metric filter, which will trigger an alarm when there are changes to AWS Organizations and send a notification to the specified SNS topic.