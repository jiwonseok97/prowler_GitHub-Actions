# Create a CloudWatch log metric filter and alarm for Management Console sign-in without MFA
resource "aws_cloudwatch_log_metric_filter" "remediation_sign_in_without_mfa" {
  name           = "remediation-sign-in-without-mfa"
  pattern        = "{$.eventName = \"ConsoleLogin\" && $.additionalEventData.MFAUsed != \"Yes\"}"
  log_group_name = "132410971304"

  metric_transformation {
    name      = "SignInWithoutMFA"
    namespace = "MyApp/SecurityMetrics"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "remediation_sign_in_without_mfa" {
  alarm_name          = "remediation-sign-in-without-mfa"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "SignInWithoutMFA"
  namespace           = "MyApp/SecurityMetrics"
  period              = "60"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Alarm when a Management Console sign-in occurs without MFA"
  alarm_actions       = ["arn:aws:sns:ap-northeast-2:${data.aws_caller_identity.current.account_id}:my-security-topic"]
}

# Create an SNS topic to receive the alarm
resource "aws_sns_topic" "remediation_security_topic" {
  name = "remediation-security-topic"
}

# Attach a policy to the SNS topic to allow CloudWatch to publish messages
resource "aws_sns_topic_policy" "remediation_security_topic_policy" {

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudwatch.amazonaws.com"
      },
      "Action": "sns:Publish",
      "Resource": "${aws_sns_topic.remediation_security_topic.arn}"
    }
  ]
}
POLICY
  arn    = aws_sns_topic.remediation_security_topic.arn
}
