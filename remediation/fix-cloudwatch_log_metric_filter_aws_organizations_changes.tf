# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Create a CloudWatch Logs metric filter for AWS Organizations changes
resource "aws_cloudwatch_log_metric_filter" "organizations_changes" {
  name           = "organizations-changes"
  pattern        = "{$.eventSource = organizations.amazonaws.com}"
  log_group_name = "arn:aws:logs:ap-northeast-2:132410971304:log-group"

  metric_transformation {
    name      = "OrganizationsChanges"
    namespace = "MyApp/Metrics"
    value     = "1"
  }
}

# Create a CloudWatch alarm to notify responders of AWS Organizations changes
resource "aws_cloudwatch_metric_alarm" "organizations_changes_alarm" {
  alarm_name          = "organizations-changes-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "OrganizationsChanges"
  namespace           = "MyApp/Metrics"
  period              = "60"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Alarm when changes are made to AWS Organizations"
  alarm_actions       = ["arn:aws:sns:ap-northeast-2:132410971304:my-alert-topic"]
}


The provided Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Creates a CloudWatch Logs metric filter that monitors for events with the source `organizations.amazonaws.com`, indicating changes to AWS Organizations.
3. Creates a CloudWatch alarm that triggers when the `OrganizationsChanges` metric is greater than or equal to 1, indicating that a change has occurred in AWS Organizations. The alarm is configured to send notifications to an SNS topic with the ARN `arn:aws:sns:ap-northeast-2:132410971304:my-alert-topic`.

This code addresses the security finding by setting up monitoring and alerting for changes to AWS Organizations, which is a recommended best practice for ensuring the security and integrity of your AWS environment.